{
  description = "Home-manager module for running web applications as Chromium desktop apps";

  outputs = { self }: {
    homeManagerModules.default = import ./module.nix;
  };
}