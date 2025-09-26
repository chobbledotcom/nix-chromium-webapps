{ pkgs, lib }:

app:
let
  iconName = "chromium-webapp-${app.name}";
in
pkgs.runCommand "${app.name}-icons" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
  mkdir -p $out/share/icons/hicolor
  for size in 16 24 32 48 64 96 128 256 512; do
    mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
    magick ${app.icon} -background none -alpha on -resize ''${size}x''${size} \
      $out/share/icons/hicolor/''${size}x''${size}/apps/${iconName}.png
  done
''