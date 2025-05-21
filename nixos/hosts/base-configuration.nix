{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../modules
    (inputs.nixpkgs + "/nixos/modules/profiles/minimal.nix")
    (inputs.nixpkgs + "/nixos/modules/profiles/headless.nix")
    ({lib, ...}: {
      options = {
        boot.kernel.structuredExtraConfig = lib.mkOption {
          type = lib.types.attrsOf lib.kernel.option;
          default = {};
          description = "Stub definition for boot.kernel.structuredExtraConfig.";
        };
      };
    })
  ];

  nixpkgs.config.allowUnfree = true;

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

  documentation.enable = false;
  documentation.nixos.enable = false;
  documentation.man.enable = false;

  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  boot.kernel.structuredExtraConfig = with lib.kernel; {
    BTRFS_FS = no;
    XFS_FS = no;
    AX25 = no;
    NETROM = no;
    ROSE = no;
    ATM = no;
    SOUND = no;
    BLUETOOTH = no;
  };

  services = {
    udev.enable = false;
    lvm.enable = false;
  };

  programs.bash = {
    promptInit = lib.mkForce "";
    interactiveShellInit = lib.mkForce "";
    shellInit = lib.mkForce "";
    shellAliases = lib.mkForce {};
  };

  users.users = let
    authorizedSshKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJOxfYfqKgUPvArW2fOl3KI/nbYODPrDslypy0xstULp alex@nixos"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGf0ZDHmsaek5djJJPYdBFHzJnSJ9fN15jLhq9JRiGdB liquidity-github-actions"
    ];
  in {
    "root" = {
      shell = pkgs.zsh;
      hashedPassword = "*";
      openssh.authorizedKeys.keys = authorizedSshKeys;
    };
    "vps" = {
      initialPassword = "password";
      isNormalUser = true;
      extraGroups = ["admin" "wheel" "docker" "podman" "users" "systemd-journal" "networkmanager"];
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
