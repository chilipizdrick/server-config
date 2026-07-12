{
  withSystem,
  inputs,
  ...
}: let
  nixosConfiguration = {
    system ? "x86_64-linux",
    modules ? [],
  }:
    withSystem system ({inputs', ...}: let
      specialArgs = {inherit inputs inputs';};
    in
      inputs.nixpkgs.lib.nixosSystem {inherit modules specialArgs;});
in {
  flake.nixosConfigurations = {
    nl-vmnano = nixosConfiguration {modules = [./hosts/nl-vmnano];};
  };
}
