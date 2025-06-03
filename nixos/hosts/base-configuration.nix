{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../modules
  ];

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      warn-dirty = false;
      experimental-features = "nix-command flakes";
      nix-path = config.nix.nixPath;
    };
    channel.enable = false;
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  zramSwap.enable = true;
  boot.tmp.cleanOnBoot = true;

  boot.loader.timeout = 0;

  users.users = let
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJOxfYfqKgUPvArW2fOl3KI/nbYODPrDslypy0xstULp alex@nixos"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRDxyYNSIY8x3niE5EdyoWdB9PXHkUarJtEX+AnHn6f alex@atlas"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOlxRZVMbj4gWyxwZafg9kyQ/TTcn/KeU6Pb46gos5x6 alex@aurora"
    ];
    defaultUser = {
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = authorizedKeys;
    };
  in {
    "root" = defaultUser;
    "vps" =
      defaultUser
      // {
        initialPassword = "password";
        isNormalUser = true;
        extraGroups = ["admin" "wheel" "docker" "podman" "users" "systemd-journal" "networkmanager" config.services.headscale.group];
      };
  };

  environment.systemPackages = with pkgs; [
    btop
    curl
    git
    openssl
    unzip
    vim
    wget
    zip
  ];
}
