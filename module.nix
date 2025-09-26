{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.services.chromium-webapps;

  webAppType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Name of the web application";
        example = "GitHub";
      };
      url = mkOption {
        type = types.str;
        description = "URL to launch the application with";
        example = "https://github.com";
      };
      icon = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Filename of icon in ~/.config/chromium-webapps/icons/";
        example = "github.svg";
      };
    };
  };

  mkDesktopEntry =
    app:
    let
      urlStripped = builtins.replaceStrings [ "https://" "http://" ] [ "" "" ] app.url;
      urlWithSlashes = builtins.replaceStrings [ "/" ] [ "__" ] urlStripped;
      urlForClass =
        if lib.hasSuffix "__" urlWithSlashes then
          (lib.removeSuffix "__" urlWithSlashes) + "_"
        else
          urlWithSlashes + "__";
      wmClass = "chrome-${urlForClass}-Default";

      launchScript = pkgs.writeShellScriptBin "${app.name}-webapp" ''
        export BROWSER="${pkgs.xdg-utils}/bin/xdg-open"
        exec ${pkgs.chromium}/bin/chromium \
          --app=${app.url} \
          --user-data-dir=$HOME/.config/chromium-webapps/${app.name} \
          --no-default-browser-check \
          --disable-features=GlobalShortcutsPortal
      '';

      iconPath = if app.icon != null then "$HOME/.config/chromium-webapps/icons/${app.icon}" else null;
    in
    pkgs.makeDesktopItem ({
      name = app.name;
      desktopName = app.name;
      exec = "${launchScript}/bin/${app.name}-webapp";
      terminal = false;
      type = "Application";
      startupWMClass = wmClass;
      categories = [
        "Network"
        "WebBrowser"
      ];
    } // lib.optionalAttrs (app.icon != null) {
      icon = iconPath;
    });

in
{
  options.services.chromium-webapps = {
    enable = mkEnableOption "Chromium web applications as desktop apps";

    user = mkOption {
      type = types.str;
      description = "User to install web applications for";
      example = "user";
    };

    webApps = mkOption {
      type = types.listOf webAppType;
      default = [ ];
      description = "List of web applications to create desktop entries for";
      example = literalExpression ''
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
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      chromium
    ];

    home-manager.users.${cfg.user} = { lib, ... }: {
      home.packages = map mkDesktopEntry cfg.webApps;
      home.activation.setupChromiumWebappProfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${concatMapStrings (app: ''
          mkdir -p "$HOME/.config/chromium-webapps/${app.name}"
        '') cfg.webApps}
      '';
    };
  };
}