{
  description = "NixOS module for running web applications as Chromium desktop apps";

  outputs = { self }: {
    nixosModules.default = import ./module.nix;
    nixosModules.chromium-webapps = import ./module.nix;
  };
}