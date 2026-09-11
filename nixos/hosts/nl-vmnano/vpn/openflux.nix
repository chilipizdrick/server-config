{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.openflux-exit;

  openfluxPkg = pkgs.buildGoModule {
    pname = "openflux";
    version = "unstable-2026-09";

    src = pkgs.fetchFromGitHub {
      owner = "p1neappleXpress";
      repo = "OpenFlux";
      rev = "main";
      hash = "sha256-KMNx9M1aFj6RifJcoziplwHpP0//DjvwNa82ZONPTkE=";
    };

    vendorHash = "sha256-eI2bUAajCvVk21n2koD4VO4hnUdkOBSsSj9d04qOS+s=";

    subPackages = ["."];

    meta = with lib; {
      description = "Network stack research tool - TCP tunnel with pluggable transports";
      homepage = "https://github.com/p1neappleXpress/OpenFlux";
      license = licenses.gpl3Only;
      platforms = platforms.linux;
      mainProgram = "universal-bypass-tool";
    };
  };

  cmdArgs =
    [
      "--exit-node"
      "--transport"
      cfg.transport
    ]
    ++ optional cfg.debug "--debug"
    ++ cfg.extraArgs;
in {
  options.services.openflux-exit = {
    enable = mkEnableOption "OpenFlux Exit Node proxy service";

    package = mkOption {
      type = types.package;
      default = openfluxPkg;
      description = "The OpenFlux package derivation to use.";
    };

    transport = mkOption {
      type = types.enum ["yandex" "oneme"];
      default = "yandex";
      description = "Covert transport backend (e.g. Yandex Docs cursor events or Max/OneMe WebRTC).";
    };

    debug = mkOption {
      type = types.bool;
      default = false;
      description = "Enable verbose debug logging.";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional command-line parameters to pass to OpenFlux.";
    };

    manageIptablesRst = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Automatically install an iptables OUTPUT rule to drop outgoing TCP RST
        packets, preventing the Linux kernel from terminating raw socket sessions.
      '';
    };
  };

  config = mkIf cfg.enable {
    # OpenFlux generates TCP packets via raw sockets; without dropping local RSTs,
    # the Linux kernel will see incoming packets for untracked sockets and send RST flags.
    networking.firewall.extraCommands = mkIf cfg.manageIptablesRst ''
      iptables -C OUTPUT -p tcp --tcp-flags RST RST -j DROP 2>/dev/null || \
        iptables -A OUTPUT -p tcp --tcp-flags RST RST -j DROP
    '';

    networking.firewall.extraStopCommands = mkIf cfg.manageIptablesRst ''
      iptables -D OUTPUT -p tcp --tcp-flags RST RST -j DROP 2>/dev/null || true
    '';

    users.users.openflux = {
      isSystemUser = true;
      group = "openflux";
    };
    users.groups.openflux = {};

    sops.secrets."openflux/url" = {
      owner = "openflux";
      group = "openflux";
      mode = "0400";
    };

    systemd.services.openflux-exit = {
      description = "OpenFlux Exit Node Service";
      after = ["network.target" "network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        ExecStart = pkgs.writeShellScript "start-openflux" ''
          set -euo pipefail
          URL=$(cat ${config.sops.secrets."openflux/url".path})
          exec ${cfg.package}/bin/universal-bypass-tool ${escapeShellArgs cmdArgs} --url "$URL"
        '';
        Restart = "always";
        RestartSec = "5s";

        # Avoid running as root; grant raw socket access explicitly
        User = "openflux";
        Group = "openflux";
        DynamicUser = false;
        AmbientCapabilities = ["CAP_NET_RAW" "CAP_NET_ADMIN"];
        CapabilityBoundingSet = ["CAP_NET_RAW" "CAP_NET_ADMIN"];

        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = false; # Required to preserve ambient capabilities on non-root user
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
      };
    };
  };
}
