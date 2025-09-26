{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.programs.chromium-webapps;

  webAppType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Name of the web application";
      };
      url = mkOption {
        type = types.str;
        description = "URL to launch the application with";
      };
      icon = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to icon file";
      };
    };
  };

  mkDesktopEntry =
    app:
    let
      urlStripped = builtins.replaceStrings [ "https://" "http://" ] [ "" "" ] app.url;
      hasTrailingSlash = lib.hasSuffix "/" app.url;
      urlWithUnderscores = builtins.replaceStrings [ "/" ] [ "__" ] urlStripped;
      urlForClass =
        if hasTrailingSlash then
          lib.removeSuffix "__" urlWithUnderscores + "_"
        else if !(lib.hasInfix "/" urlStripped) then
          urlWithUnderscores + "__"
        else
          urlWithUnderscores;
      wmClass = "chrome-${urlForClass}-Default";

      launchScript = pkgs.writeShellScriptBin "${app.name}-webapp" ''
        exec ${pkgs.chromium}/bin/chromium \
          --app=${app.url} \
          --user-data-dir=$HOME/.config/chromium-webapps/${app.name} \
          --no-default-browser-check \
          --disable-features=GlobalShortcutsPortal
      '';

      desktopContent = ''
        [Desktop Entry]
        Version=1.4
        Type=Application
        Name=${app.name}
        Exec=${launchScript}/bin/${app.name}-webapp
        Terminal=false
        Categories=Network;WebBrowser;
        StartupWMClass=${wmClass}
        ${lib.optionalString (app.icon != null) "Icon=chromium-webapp-${app.name}"}
      '';
    in
    pkgs.runCommand "${app.name}-desktop" { } ''
      mkdir -p $out/share/applications
      cat > $out/share/applications/${app.name}.desktop <<EOF
      ${desktopContent}
      EOF
    '';

in
{
  options.programs.chromium-webapps = {
    enable = mkEnableOption "Chromium web applications as desktop apps";

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

  config = mkIf cfg.enable (
    let
      mkIconPackage = import ./icons.nix { inherit pkgs lib; };

      iconPackages = lib.filter (x: x != null) (
        map (
          app:
          if app.icon != null then
            mkIconPackage app
          else
            null
        ) cfg.webApps
      );
    in
    {
      home.packages = [ pkgs.chromium ] ++ (map mkDesktopEntry cfg.webApps) ++ iconPackages;

      home.activation.setupChromiumWebappProfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${concatMapStrings (app: ''
          mkdir -p "$HOME/.config/chromium-webapps/${app.name}"
        '') cfg.webApps}
      '';
    }
  );
}
