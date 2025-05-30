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
    authorizedSshKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJOxfYfqKgUPvArW2fOl3KI/nbYODPrDslypy0xstULp alex@nixos"
    ];
  in {
    "root" = {
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = authorizedSshKeys;
    };
    "vps" = {
      initialPassword = "password";
      isNormalUser = true;
      extraGroups = ["admin" "wheel" "docker" "podman" "users" "systemd-journal" "networkmanager" config.services.headscale.group];
      openssh.authorizedKeys.keys = authorizedSshKeys;
      shell = pkgs.zsh;
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
