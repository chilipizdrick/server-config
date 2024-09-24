{
  description = "Server configuration flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.05";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (self) outputs;
  in {
    formatter."x86_64-linux" = nixpkgs.legacyPackages."x86_64-linux".alejandra;

    nixosConfigurations = {
      "nl-vps" = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./nixos/hosts/nl-vps/configuration.nix
        ];
      };
    };
  };
}
