{
  config,
  pkgs,
  lib,
  ...
}: let
  openflux = pkgs.buildGoModule rec {
    pname = "openflux";
    version = "0.0.3";

    src = pkgs.fetchFromGitHub {
      owner = "p1neappleXpress";
      repo = "OpenFlux";
      rev = version;
      hash = "sha256-uneE0lOxTglkX7yfiQMusgO0YHi+wCpTFtdHLeHvscs=";
    };

    vendorHash = "sha256-IyzB0CH3Wzw0hWi5ZDplR1G9nxWvGSGBvOX52PQpoCQ=";
    subPackages = ["."];

    env.CGO_ENABLED = 0;
    ldflags = ["-s" "-w"];

    meta = with lib; {
      description = "OpenFlux network tunnel exit node";
      homepage = "https://github.com/p1neappleXpress/OpenFlux";
      license = licenses.gpl3Only;
      platforms = platforms.linux;
      mainProgram = "openflux";
    };
  };

  startScript = pkgs.writeShellScript "openflux-exit-start" ''
    set -euo pipefail

    SECRET_PATH="${config.sops.secrets."openflux/url".path}"
    if [ ! -r "$SECRET_PATH" ]; then
      echo "Error: Secret file $SECRET_PATH is missing or not readable" >&2
      exit 1
    fi

    TARGET_URL="$(cat "$SECRET_PATH")"
    if [ -z "$TARGET_URL" ]; then
      echo "Error: Document URL inside $SECRET_PATH is empty" >&2
      exit 1
    fi

    exec ${openflux}/bin/openflux \
      --role=exit \
      --mode=l3 \
      --transport=yandex \
      --url="$TARGET_URL" \
      --debug
  '';
in {
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

  networking.firewall.extraCommands = ''
    iptables -C OUTPUT -p tcp --tcp-flags RST RST -j DROP 2>/dev/null || \
      iptables -A OUTPUT -p tcp --tcp-flags RST RST -j DROP
  '';

  networking.firewall.extraStopCommands = ''
    iptables -D OUTPUT -p tcp --tcp-flags RST RST -j DROP 2>/dev/null || true
  '';

  systemd.services.openflux-exit = {
    description = "OpenFlux Exit Node Service (L3 Yandex Transport)";
    wantedBy = ["multi-user.target"];
    after = ["network.target" "network-online.target"];
    wants = ["network-online.target"];

    serviceConfig = {
      ExecStart = "${startScript}";
      Restart = "always";
      RestartSec = "5s";

      User = "openflux";
      Group = "openflux";
      AmbientCapabilities = ["CAP_NET_RAW" "CAP_NET_ADMIN"];
      CapabilityBoundingSet = ["CAP_NET_RAW" "CAP_NET_ADMIN"];

      ProtectSystem = "strict";
      ProtectHome = true;
      NoNewPrivileges = false;
      PrivateTmp = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
    };
  };
}
