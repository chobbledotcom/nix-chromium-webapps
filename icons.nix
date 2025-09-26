{ pkgs, lib }:

app:
let
  iconName = "chromium-webapp-${app.name}";
  isSvg = lib.hasSuffix ".svg" (builtins.toString app.icon);
in
pkgs.runCommand "${app.name}-icons" { nativeBuildInputs = [ pkgs.librsvg pkgs.imagemagick ]; } ''
  mkdir -p $out/share/icons/hicolor
  for size in 16 24 32 48 64 96 128 256 512; do
    mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
    ${if isSvg then ''
      rsvg-convert -w $size -h $size -f png -o $out/share/icons/hicolor/''${size}x''${size}/apps/${iconName}.png ${app.icon}
    '' else ''
      magick ${app.icon} -resize ''${size}x''${size} $out/share/icons/hicolor/''${size}x''${size}/apps/${iconName}.png
    ''}
  done
''