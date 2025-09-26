# nix-chromium-webapps

A NixOS flake module for creating Chromium-based web applications as desktop entries.

## Features

- Creates isolated Chromium profiles for each web app
- Generates proper desktop entries with WM_CLASS for window manager integration
- Supports custom icons
- External links open in system default browser

## Usage

### In your flake.nix

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chromium-webapps.url = "github:chobbledotcom/nix-chromium-webapps";
  };

  outputs = { self, nixpkgs, chromium-webapps, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      modules = [
        chromium-webapps.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

### In your configuration.nix

```nix
{
  services.chromium-webapps = {
    enable = true;
    user = "yourusername";
    webApps = [
      {
        name = "GitHub";
        url = "https://github.com";
        icon = ./path/to/github.svg;
      }
      {
        name = "Gmail";
        url = "https://mail.google.com";
        icon = ./path/to/gmail.png;
      }
    ];
  };
}
```

### Loading from a separate file

```nix
{
  services.chromium-webapps = {
    enable = true;
    user = "yourusername";
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

- `services.chromium-webapps.enable` - Enable the module (boolean)
- `services.chromium-webapps.user` - Username to install apps for (string)
- `services.chromium-webapps.webApps` - List of web applications (list of attrsets)
  - `name` - Application name (string)
  - `url` - URL to open (string)
  - `icon` - Path to icon file (path, optional)

## Requirements

- NixOS with home-manager
- Chromium will be automatically installed

## Data Storage

Each web app stores its profile data in `~/.config/chromium-webapps/<app-name>/`