# nix-chromium-webapps

A home-manager module for creating Chromium-based web applications as desktop entries.

## Features

- Creates isolated Chromium profiles for each web app
- Generates proper desktop entries with the right WM_CLASS for window manager integration
- Supports custom icons via XDG icon theme system
- External links **won't** open in your preferred browser, though. Boooo. If you can crack that, please submit a PR.

## Usage

### In your flake.nix

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    chromium-webapps.url = "github:chobbledotcom/nix-chromium-webapps";
  };

  outputs = { self, nixpkgs, home-manager, chromium-webapps, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      modules = [
        home-manager.nixosModules.home-manager
        ./configuration.nix
      ];
    };
  };
}
```

### In your home-manager configuration

```nix
{ inputs, ... }:
{
  imports = [ inputs.chromium-webapps.homeManagerModules.default ];

  programs.chromium-webapps = {
    enable = true;
    webApps = [
      {
        name = "GitHub";
        url = "https://github.com";
        icon = ./icons/github.svg;
      }
      {
        name = "Gmail";
        url = "https://mail.google.com";
        icon = ./icons/gmail.png;
      }
    ];
  };
}
```

### Loading from a separate file

```nix
{ inputs, ... }:
{
  imports = [ inputs.chromium-webapps.homeManagerModules.default ];

  programs.chromium-webapps = {
    enable = true;
    webApps = import ./chromium-apps.nix;
  };
}
```

Where `chromium-apps.nix` contains:

```nix
[
  {
    name = "GitHub";
    url = "https://github.com";
    icon = ./icons/github.svg;
  }
  {
    name = "Gmail";
    url = "https://mail.google.com";
    icon = ./icons/gmail.png;
  }
]
```

## Options

- `programs.chromium-webapps.enable` - Enable the module (boolean)
- `programs.chromium-webapps.webApps` - List of web applications (list of attrsets)
  - `name` - Application name (string)
  - `url` - URL to open (string)
  - `icon` - Path to icon file (path, optional)

## Requirements

- [home-manager](https://github.com/nix-community/home-manager)
- Chromium will be automatically installed

## Icons

Icons are passed as paths and automatically converted to PNG at multiple sizes (16, 24, 32, 48, 64, 96, 128, 256, 512) and installed to the XDG icon theme system. SVG icons are rendered with transparent backgrounds preserved. Desktop environments will automatically find and display them.

## Data Storage

Each web app stores its profile data in `~/.config/chromium-webapps/<app-name>/`
