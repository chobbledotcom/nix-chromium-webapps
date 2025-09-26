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
        type = types.nullOr types.path;
        default = null;
        description = "Path to icon file for the desktop entry";
        example = "./icons/github.svg";
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

      desktopItem = pkgs.makeDesktopItem ({
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
        icon = app.name;
      });
    in
    if app.icon != null then
      pkgs.symlinkJoin {
        name = "${app.name}-desktop-with-icon";
        paths = [ desktopItem ];
        postBuild = ''
          rm -rf $out/share
          cp -r ${desktopItem}/share $out/share
          chmod -R u+w $out/share
          mkdir -p $out/share/icons/hicolor/scalable/apps
          cp ${app.icon} $out/share/icons/hicolor/scalable/apps/${app.name}.${
            if lib.hasSuffix ".svg" (builtins.toString app.icon) then "svg" else "png"
          }
        '';
      }
    else
      desktopItem;

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