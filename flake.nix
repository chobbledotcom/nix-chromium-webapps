{
  description = "NixOS module for running web applications as Chromium desktop apps";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosModules.default = import ./module.nix;
    nixosModules.chromium-webapps = import ./module.nix;
  };
}