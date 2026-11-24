{
  stdenv,
  kdePackages,
  pkg-config,
  gtk3,
}:
stdenv.mkDerivation {
  pname = "gtk3-colorreload";
  inherit (kdePackages.kde-gtk-config) version src;

  nativeBuildInputs = [pkg-config];
  buildInputs = [gtk3];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    $CC -shared -fPIC -O2 -fvisibility=hidden \
      color-reload-module/reloader.c \
      $(pkg-config --cflags --libs gtk+-3.0) \
      -o libcolorreload-gtk-module.so
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 libcolorreload-gtk-module.so -t $out/lib/gtk-3.0/modules
    runHook postInstall
  '';

  meta = {
    description = "GTK3 module from kde-gtk-config that live-reloads ~/.config/gtk-3.0/colors.css";
    platforms = gtk3.meta.platforms;
  };
}
