{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.openflux;
  openfluxPkg = cfg.package;

  # Determine transport priority based on the chosen strategy
  resolvePriority = transportName: explicitPriority:
    if cfg.strategy == "custom"
    then
      if explicitPriority != null
      then explicitPriority
      else 50
    else if cfg.strategy == "speed-first"
    then
      if transportName == "direct"
      then 110
      else if transportName == "vyandex"
      then 100
      else if transportName == "mailru"
      then 90
      else if transportName == "cupsonline"
      then 70
      else if transportName == "boards"
      then 60
      else 50
    else # covert-first (default, censorship-resistant)
      if transportName == "vyandex"
      then 100
      else if transportName == "mailru"
      then 90
      else if transportName == "cupsonline"
      then 70
      else if transportName == "boards"
      then 60
      else if transportName == "direct"
      then 50
      else 40;

  directPriority = resolvePriority "direct" cfg.transports.direct.priority;
  vyandexPriority = resolvePriority "vyandex" cfg.transports.vyandex.priority;
  mailruPriority = resolvePriority "mailru" cfg.transports.mailru.priority;
  cupsonlinePriority = resolvePriority "cupsonline" cfg.transports.cupsonline.priority;
  boardsPriority = resolvePriority "boards" cfg.transports.boards.priority;

  # Dynamic Pre-Start Script:
  # Runs as root (+ prefix) so it can read secret files created by sops-nix in /run/secrets/
  # even with 0400 root:root permissions.
  # Dynamically generates node.conf and share-link.txt at runtime without exposing secrets to /nix/store.
  preStartScript = pkgs.writeShellScript "openflux-pre-start" ''
        set -euo pipefail
        umask 077

        STATE_DIR="${cfg.stateDir}"
        mkdir -p "$STATE_DIR"

        # 1. Source environmentFile if provided (e.g. sops-nix env file)
        ENV_FILE="${
      if cfg.environmentFile != null
      then toString cfg.environmentFile
      else ""
    }"
        if [ -n "$ENV_FILE" ] && [ -f "$ENV_FILE" ]; then
          set -a
          # shellcheck disable=SC1090
          . "$ENV_FILE"
          set +a
        fi

        # Helper function to resolve secret from: 1) File path, 2) Environment variable, 3) Fallback static value
        resolve_val() {
          local file_path="$1"
          local env_var_name="$2"
          local fallback_val="$3"
          local res=""

          if [ -n "$file_path" ] && [ -f "$file_path" ]; then
            res=$(cat "$file_path" | tr -d '\r\n\t ' || true)
          fi

          if [ -z "$res" ] && [ -n "$env_var_name" ]; then
            res="''${!env_var_name:-}"
          fi

          if [ -z "$res" ]; then
            res="$fallback_val"
          fi

          printf '%s' "$res"
        }

        # 2. Resolve Encryption Key
        KEY_FILE="${
      if cfg.encryptionKeyFile != null
      then toString cfg.encryptionKeyFile
      else ""
    }"
        KEY=$(resolve_val "$KEY_FILE" "OPENFLUX_KEY" "")

        if [ -n "$KEY" ]; then
          echo "$KEY" > "$STATE_DIR/encryption-key"
          chmod 0600 "$STATE_DIR/encryption-key"
        elif [ -f "$STATE_DIR/encryption-key" ]; then
          KEY=$(cat "$STATE_DIR/encryption-key" | tr -d '\r\n\t ')
        else
          echo "Generating fresh AES-256-GCM encryption key..."
          ${pkgs.openssl}/bin/openssl rand -hex 32 > "$STATE_DIR/encryption-key"
          chmod 0600 "$STATE_DIR/encryption-key"
          KEY=$(cat "$STATE_DIR/encryption-key" | tr -d '\r\n\t ')
        fi

        # 3. Resolve Public Host for direct transport
        STATIC_HOST="${
      if cfg.publicHost != null
      then cfg.publicHost
      else ""
    }"
        HOST=$(resolve_val "" "OPENFLUX_PUBLIC_HOST" "$STATIC_HOST")
        if [ -z "$HOST" ]; then
          HOST=$(${pkgs.iproute2}/bin/ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || echo "127.0.0.1")
        fi

        # 4. Resolve URLs from secret files, environment variables, or static options
        VYANDEX_URL_FILE="${
      if cfg.transports.vyandex.urlFile != null
      then toString cfg.transports.vyandex.urlFile
      else ""
    }"
        VYANDEX_STATIC_URL="${
      if cfg.transports.vyandex.url != null
      then cfg.transports.vyandex.url
      else ""
    }"
        VYANDEX_URL=$(resolve_val "$VYANDEX_URL_FILE" "OPENFLUX_VYANDEX_URL" "$VYANDEX_STATIC_URL")

        MAILRU_URL_FILE="${
      if cfg.transports.mailru.urlFile != null
      then toString cfg.transports.mailru.urlFile
      else ""
    }"
        MAILRU_STATIC_URL="${
      if cfg.transports.mailru.url != null
      then cfg.transports.mailru.url
      else ""
    }"
        MAILRU_URL=$(resolve_val "$MAILRU_URL_FILE" "OPENFLUX_MAILRU_URL" "$MAILRU_STATIC_URL")

        CUPS_URL_FILE="${
      if cfg.transports.cupsonline.urlFile != null
      then toString cfg.transports.cupsonline.urlFile
      else ""
    }"
        CUPS_STATIC_URL="${
      if cfg.transports.cupsonline.url != null
      then cfg.transports.cupsonline.url
      else ""
    }"
        CUPS_URL=$(resolve_val "$CUPS_URL_FILE" "OPENFLUX_CUPS_URL" "$CUPS_STATIC_URL")

        BOARDS_URL_FILE="${
      if cfg.transports.boards.urlFile != null
      then toString cfg.transports.boards.urlFile
      else ""
    }"
        BOARDS_STATIC_URL="${
      if cfg.transports.boards.url != null
      then cfg.transports.boards.url
      else ""
    }"
        BOARDS_URL=$(resolve_val "$BOARDS_URL_FILE" "OPENFLUX_BOARDS_URL" "$BOARDS_STATIC_URL")

        # 5. Handle Yandex Cookies file if specified
        YANDEX_COOKIES_SRC="${
      if cfg.transports.vyandex.cookiesFile != null
      then toString cfg.transports.vyandex.cookiesFile
      else ""
    }"
        if [ -n "$YANDEX_COOKIES_SRC" ] && [ -f "$YANDEX_COOKIES_SRC" ]; then
          cp -f "$YANDEX_COOKIES_SRC" "$STATE_DIR/yandex-cookies.txt"
          chmod 0600 "$STATE_DIR/yandex-cookies.txt"
        elif [ -n "''${OPENFLUX_YANDEX_COOKIES:-}" ]; then
          echo "$OPENFLUX_YANDEX_COOKIES" > "$STATE_DIR/yandex-cookies.txt"
          chmod 0600 "$STATE_DIR/yandex-cookies.txt"
        fi

        # 6. Determine SessionContext (highest priority document URL)
        SESSION_CONTEXT="http://#"
        HIGHEST_PRI=-1

        ${optionalString cfg.transports.vyandex.enable ''
      if [ -n "$VYANDEX_URL" ] && [ ${toString vyandexPriority} -gt "$HIGHEST_PRI" ]; then
        SESSION_CONTEXT="$VYANDEX_URL"
        HIGHEST_PRI=${toString vyandexPriority}
      fi
    ''}

        ${optionalString cfg.transports.mailru.enable ''
      if [ -n "$MAILRU_URL" ] && [ ${toString mailruPriority} -gt "$HIGHEST_PRI" ]; then
        SESSION_CONTEXT="$MAILRU_URL"
        HIGHEST_PRI=${toString mailruPriority}
      fi
    ''}

        ${optionalString cfg.transports.boards.enable ''
      if [ -n "$BOARDS_URL" ] && [ ${toString boardsPriority} -gt "$HIGHEST_PRI" ]; then
        SESSION_CONTEXT="$BOARDS_URL"
        HIGHEST_PRI=${toString boardsPriority}
      fi
    ''}

        # 7. Generate runtime node.conf (kept strictly in STATE_DIR with 0600 permissions)
        cat > "$STATE_DIR/node.conf" <<EOF
    # OpenFlux Configuration generated dynamically by NixOS
    Role = ${cfg.role}
    Mode = ${cfg.mode}
    EncryptionKeyFile = $STATE_DIR/encryption-key
    CookieStore = $STATE_DIR/cookies.json
    URL = $SESSION_CONTEXT
    Codec = ${cfg.codec}
    Debug = ${toString cfg.debug}
    EOF

        ${optionalString cfg.transports.vyandex.enable ''
          if [ -n "$VYANDEX_URL" ]; then
            cat >> "$STATE_DIR/node.conf" <<EOF

      [Transport vyandex]
      Type = vyandex
      Priority = ${toString vyandexPriority}
      URL = $VYANDEX_URL
      EOF
          fi
    ''}

        ${optionalString cfg.transports.mailru.enable ''
          if [ -n "$MAILRU_URL" ]; then
            cat >> "$STATE_DIR/node.conf" <<EOF

      [Transport mailru]
      Type = mailru
      Priority = ${toString mailruPriority}
      URL = $MAILRU_URL
      EOF
          fi
    ''}

        ${optionalString cfg.transports.cupsonline.enable ''
          cat >> "$STATE_DIR/node.conf" <<EOF

      [Transport cupsonline]
      Type = cupsonline
      Priority = ${toString cupsonlinePriority}
      EOF
          if [ -n "$CUPS_URL" ]; then
            echo "URL = $CUPS_URL" >> "$STATE_DIR/node.conf"
          fi
    ''}

        ${optionalString cfg.transports.boards.enable ''
          if [ -n "$BOARDS_URL" ]; then
            cat >> "$STATE_DIR/node.conf" <<EOF

      [Transport boards]
      Type = boards
      Priority = ${toString boardsPriority}
      URL = $BOARDS_URL
      EOF
          fi
    ''}

        ${optionalString cfg.transports.direct.enable ''
          cat >> "$STATE_DIR/node.conf" <<EOF

      [Transport direct]
      Type = direct
      Priority = ${toString directPriority}
      Listen = ${cfg.transports.direct.listenAddress}:${toString cfg.transports.direct.port}
      EOF
    ''}

        cat >> "$STATE_DIR/node.conf" <<'EOF'
    ${cfg.extraConfig}
    EOF
        chmod 0600 "$STATE_DIR/node.conf"

        # 8. Generate client openflux:// share link JSON
        SHARE_JSON=$(${pkgs.jq}/bin/jq -n \
          --arg name "${cfg.channelName}" \
          --arg secret "$KEY" \
          --arg context "$SESSION_CONTEXT" \
          --arg codec "${cfg.codec}" \
          --arg host "$HOST" \
          --argjson negotiate ${
      if cfg.negotiate
      then "true"
      else "false"
    } \
          --argjson vyandex_en ${
      if cfg.transports.vyandex.enable
      then "true"
      else "false"
    } \
          --arg vyandex_url "$VYANDEX_URL" \
          --argjson vyandex_pri ${toString vyandexPriority} \
          --argjson mailru_en ${
      if cfg.transports.mailru.enable
      then "true"
      else "false"
    } \
          --arg mailru_url "$MAILRU_URL" \
          --argjson mailru_pri ${toString mailruPriority} \
          --argjson cups_en ${
      if cfg.transports.cupsonline.enable
      then "true"
      else "false"
    } \
          --arg cups_url "$CUPS_URL" \
          --argjson cups_pri ${toString cupsonlinePriority} \
          --argjson direct_en ${
      if cfg.transports.direct.enable
      then "true"
      else "false"
    } \
          --argjson direct_port ${toString cfg.transports.direct.port} \
          --argjson direct_pri ${toString directPriority} \
          '{
            name: $name,
            negotiate: $negotiate,
            codec: $codec,
            secret: $secret,
            context: $context,
            transports: (
              [
                (if ($vyandex_en and ($vyandex_url != "")) then {type: "vyandex", url: $vyandex_url, priority: $vyandex_pri} else empty end),
                (if ($mailru_en and ($mailru_url != "")) then {type: "mailru", url: $mailru_url, priority: $mailru_pri} else empty end),
                (if ($cups_en and ($cups_url != "")) then {type: "cupsonline", url: $cups_url, priority: $cups_pri} else empty end),
                (if $direct_en then {type: "direct", dial: "\($host):\($direct_port)", priority: $direct_pri} else empty end)
              ]
            )
          }')

        LINK_RESULT=$(${openfluxPkg}/bin/openflux --make-link "$SHARE_JSON" || true)
        LINK=$(echo "$LINK_RESULT" | ${pkgs.jq}/bin/jq -r .link 2>/dev/null || echo "")

        if [ -n "$LINK" ] && [ "$LINK" != "null" ]; then
          echo "$LINK" > "$STATE_DIR/share-link.txt"
          chmod 0640 "$STATE_DIR/share-link.txt"
          echo "=================================================================="
          echo "OpenFlux Server Ready!"
          echo "Client Share Link: $LINK"
          echo "Run 'openflux-share' anytime to show the QR code."
          echo "=================================================================="
        fi

        # 9. Set permissions for unprivileged user
        ${optionalString (cfg.mode == "l4") ''
      if id -u openflux >/dev/null 2>&1; then
        chown -R openflux:openflux "$STATE_DIR"
      fi
    ''}
  '';

  # Command-line utility to display the share link & QR code
  shareTool = pkgs.writeShellScriptBin "openflux-share" ''
    set -euo pipefail

    SHARE_FILE="${cfg.stateDir}/share-link.txt"
    if [ ! -f "$SHARE_FILE" ]; then
      echo "Share link not found at $SHARE_FILE." >&2
      echo "Ensure the openflux service has started successfully (systemctl status openflux)." >&2
      exit 1
    fi

    LINK=$(cat "$SHARE_FILE" | tr -d ' \n\r\t')

    echo "======================================================================"
    echo " OpenFlux Client Configuration Link & QR Code"
    echo "======================================================================"
    echo ""
    echo "Channel: ${cfg.channelName}"
    echo "Link:    $LINK"
    echo ""
    echo "Terminal QR code (scan with OpenFlux Android or import into OpenFluxDesktop):"
    echo ""
    ${pkgs.qrencode}/bin/qrencode -t ANSIUTF8 "$LINK"
    echo ""
    echo "Import instructions:"
    echo "  1. Android App: Tap '+' -> 'Scan QR Code' or paste the link."
    echo "  2. Desktop App: Tap '+' -> 'Add profile from link/QR' -> paste the link."
    echo "======================================================================"
  '';

  # Runtime service starter script
  runScript = pkgs.writeShellScript "openflux-start" ''
    set -euo pipefail

    COOKIES_ARG=""
    if [ -f "${cfg.stateDir}/yandex-cookies.txt" ]; then
      COOKIES_ARG="--yandex-cookies-file=${cfg.stateDir}/yandex-cookies.txt"
    fi

    exec ${openfluxPkg}/bin/openflux \
      --config=${cfg.stateDir}/node.conf \
      --share \
      ${optionalString (cfg.publicHost != null) "--share-host=${cfg.publicHost}"} \
      $COOKIES_ARG
  '';
in {
  options.services.openflux = {
    enable = mkEnableOption "OpenFlux tunnel server/exit node with multi-transport support";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./package.nix {};
      defaultText = literalExpression "pkgs.callPackage ../pkgs/openflux {}";
      description = "The OpenFlux package to use.";
    };

    role = mkOption {
      type = types.enum ["exit" "client"];
      default = "exit";
      description = "OpenFlux role (typically 'exit' for server tunnel).";
    };

    mode = mkOption {
      type = types.enum ["l4" "l3"];
      default = "l4";
      description = ''
        Exit backend mode:
        - `l4`: Stream proxy using Google's gVisor TCP/IP stack. Runs unprivileged, requires no root, no firewall packet mangling. Highly recommended for stability.
        - `l3`: Raw IP forwarding (SNAT/DNAT). Requires Linux root or CAP_NET_RAW/CAP_NET_ADMIN capabilities.
      '';
    };

    strategy = mkOption {
      type = types.enum ["covert-first" "speed-first" "custom"];
      default = "covert-first";
      description = ''
        Failover and transport strategy:
        - `covert-first`: Prioritizes stealth and DPI bypass (vyandex: 100, mailru: 90, cupsonline: 70, direct: 50). Direct TCP is used only as fallback.
        - `speed-first`: Prioritizes raw wire-speed direct TCP (direct: 110, vyandex: 100, mailru: 90, cupsonline: 70). Falls back seamlessly to covert carriers if direct TCP is blocked by DPI.
        - `custom`: Uses the explicit priority integer set on each transport.
      '';
    };

    channelName = mkOption {
      type = types.str;
      default = "OpenFlux-Node";
      description = "Display name for the connection profile generated in openflux:// links.";
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/openflux";
      description = "State directory where cookies, encryption key and share link are stored.";
    };

    environmentFile = mkOption {
      type = types.nullOr (types.either types.path types.str);
      default = null;
      example = "/run/secrets/openflux.env";
      description = ''
        Path to an environment file (e.g. decrypted by sops-nix during activation)
        containing secret values such as:
        - `OPENFLUX_KEY` (64 hex characters)
        - `OPENFLUX_VYANDEX_URL`
        - `OPENFLUX_MAILRU_URL`
        - `OPENFLUX_CUPS_URL`
        - `OPENFLUX_BOARDS_URL`
        - `OPENFLUX_PUBLIC_HOST`
        - `OPENFLUX_YANDEX_COOKIES`
      '';
    };

    encryptionKeyFile = mkOption {
      type = types.nullOr (types.either types.path types.str);
      default = null;
      example = "/run/secrets/openflux-key";
      description = ''
        Path to file containing the 64-hex-character AES-256-GCM encryption key.
        Can point to a sops-nix secret file created during activation.
        If null and no OPENFLUX_KEY is in environmentFile, a cryptographically secure random key
        is automatically created on first boot in stateDir.
      '';
    };

    publicHost = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Public IP or domain name that clients will dial for the direct transport. If null, automatically auto-detected.";
    };

    negotiate = mkOption {
      type = types.bool;
      default = true;
      description = "Require authenticated capability negotiation on both peers.";
    };

    codec = mkOption {
      type = types.enum ["batched" "legacy"];
      default = "batched";
      description = "Codec for tunnel packets ('batched' enables zstd compression and packet coalescing).";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically open direct transport TCP port in networking.firewall.";
    };

    debug = mkOption {
      type = types.ints.between 0 3;
      default = 0;
      description = "Debug logging verbosity (0=off, 1=packet movement, 2=operational logs, 3=hexdump).";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Additional raw configuration lines appended to node.conf.";
    };

    transports = {
      # 1. Direct TCP
      direct = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Direct TCP transport between client and exit node.";
        };
        priority = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Priority when strategy is custom (higher = dialed first).";
        };
        listenAddress = mkOption {
          type = types.str;
          default = "0.0.0.0";
          description = "Listen IP address for direct TCP connection.";
        };
        port = mkOption {
          type = types.port;
          default = 8445;
          description = "TCP port for direct transport.";
        };
      };

      # 2. Yandex Volga (Top covert transport)
      vyandex = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Yandex Volga covert transport (WebSocket + HTTP relay).";
        };
        priority = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Priority when strategy is custom.";
        };
        url = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "https://docs.yandex.ru/edit/d/1234567890abcdef1234567890abcdef";
          description = "Yandex Docs document URL. If urlFile or environmentFile is used, this can be null.";
        };
        urlFile = mkOption {
          type = types.nullOr (types.either types.path types.str);
          default = null;
          example = "/run/secrets/openflux-vyandex-url";
          description = "Path to file containing Yandex Docs URL (e.g. from sops-nix).";
        };
        cookiesFile = mkOption {
          type = types.nullOr (types.either types.path types.str);
          default = null;
          example = "/run/secrets/yandex-cookies.txt";
          description = "Optional Netscape cookies.txt file for logged-in Yandex sessions (e.g. from sops-nix).";
        };
      };

      # 3. Mail.ru Cloud Docs
      mailru = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Mail.ru Cloud Docs covert transport (WebSocket).";
        };
        priority = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Priority when strategy is custom.";
        };
        url = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "https://cloud.mail.ru/public/xxxx/yyyy";
          description = "Mail.ru Cloud public document URL. If urlFile or environmentFile is used, this can be null.";
        };
        urlFile = mkOption {
          type = types.nullOr (types.either types.path types.str);
          default = null;
          example = "/run/secrets/openflux-mailru-url";
          description = "Path to file containing Mail.ru Cloud URL (e.g. from sops-nix).";
        };
      };

      # 4. Cups.online
      cupsonline = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Cups.online Centrifugo room transport (striped ARQ).";
        };
        priority = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Priority when strategy is custom.";
        };
        url = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Base64 encoded room list (empty to generate fresh rooms at startup).";
        };
        urlFile = mkOption {
          type = types.nullOr (types.either types.path types.str);
          default = null;
          example = "/run/secrets/openflux-cups-url";
          description = "Path to file containing cups.online room list (e.g. from sops-nix).";
        };
      };

      # 5. Yandex Boards
      boards = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Yandex Board WebSocket covert transport.";
        };
        priority = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Priority when strategy is custom.";
        };
        url = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "https://board.yandex.ru/edit/d/1234567890abcdef1234567890abcdef";
          description = "Yandex Board document URL.";
        };
        urlFile = mkOption {
          type = types.nullOr (types.either types.path types.str);
          default = null;
          example = "/run/secrets/openflux-boards-url";
          description = "Path to file containing Yandex Board URL (e.g. from sops-nix).";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # System packages: include openflux CLI and the openflux-share helper
    environment.systemPackages = [
      openfluxPkg
      shareTool
    ];

    # Create dedicated unprivileged system user/group for l4 mode
    users.users.openflux = mkIf (cfg.mode == "l4") {
      isSystemUser = true;
      group = "openflux";
      description = "OpenFlux tunnel daemon user";
      home = cfg.stateDir;
      createHome = false;
    };

    users.groups.openflux = mkIf (cfg.mode == "l4") {};

    # Firewall configuration
    networking.firewall.allowedTCPPorts = mkIf (cfg.openFirewall && cfg.transports.direct.enable) [
      cfg.transports.direct.port
    ];

    # Enable IPv4 forwarding if l3 mode is selected
    boot.kernel.sysctl = mkIf (cfg.mode == "l3") {
      "net.ipv4.ip_forward" = 1;
    };

    # Systemd Service
    systemd.services.openflux = {
      description = "OpenFlux Multi-Transport Tunnel Server (%i)";
      after = ["network-online.target"] ++ optional (config ? sops) "sops-nix.service";
      wants = ["network-online.target"] ++ optional (config ? sops) "sops-nix.service";
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        StateDirectory = "openflux";
        WorkingDirectory = cfg.stateDir;
        Restart = "always";
        RestartSec = 5;

        # User and permissions
        User =
          if cfg.mode == "l3"
          then "root"
          else "openflux";
        Group =
          if cfg.mode == "l3"
          then "root"
          else "openflux";

        # Linux hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = cfg.mode == "l4";
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK"];
        AmbientCapabilities = mkIf (cfg.mode == "l3") ["CAP_NET_RAW" "CAP_NET_ADMIN"];

        # Environment file if specified
        EnvironmentFile = mkIf (cfg.environmentFile != null) (toString cfg.environmentFile);

        # PreStart runs with '+' prefix (root) to read any sops-nix secret files from /run/secrets/
        # regardless of ownership, generates node.conf and share-link.txt, and chowns to openflux.
        ExecStartPre = "+${preStartScript}";

        # Main ExecStart
        ExecStart = "${runScript}";
      };
    };
  };
}
