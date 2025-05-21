{
  description = "Server configuration flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;
      };
      flake = {
        nixosConfigurations."nl-vps" = inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs;};
          modules = [
            ./nixos/hosts/nl-vps/configuration.nix
          ];
        };
      };
    };
}
