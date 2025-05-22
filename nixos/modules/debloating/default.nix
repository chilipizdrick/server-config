{inputs, ...}: {
  imports = [
    (inputs.nixpkgs + "/nixos/modules/profiles/minimal.nix")
    (inputs.nixpkgs + "/nixos/modules/profiles/headless.nix")
  ];

  environment.defaultPackages = [];
  xdg = {
    icons.enable = false;
    mime.enable = false;
    sounds.enable = false;
  };

  documentation = {
    enable = false;
    nixos.enable = false;
    man.enable = false;
  };
}
