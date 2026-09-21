{
  description = "Server configuration flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    schizoid.url = "github:chilipizdrick/schizoid";
  };

  outputs = {nixpkgs, ...} @ inputs: let
    lib = nixpkgs.lib;
    modules = [./modules];
  in {
    nixosConfigurations.nl-vmnano = lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = modules ++ [./hosts/nl-vmnano];
    };
  };
}
