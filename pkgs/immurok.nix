{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  glib,
  gobject-introspection,
  wrapGAppsHook4,
  dbus,
  gtk4,
  libadwaita,
  pam,
  python3,
  libnotify,
  systemd,
}: let
  python = python3.withPackages (ps: [ps.dbus-fast ps.pygobject3]);
in
  rustPlatform.buildRustPackage (finalAttrs: {
    pname = "immurok";
    version = "0.9.4";

    src = fetchFromGitHub {
      owner = "immurok";
      repo = "app-linux-rs";
      tag = "v${finalAttrs.version}";
      hash = "sha256-DyPXYTilZvw3XYPZTerdHP2q3uWNXGm2MAXv5BkotNg=";
    };

    cargoHash = "sha256-iohheKYsPlw+LuZVz+900Adbr22RM4/Yqtn6K2d3oSA=";

    nativeBuildInputs = [
      pkg-config
      glib
      gobject-introspection
      wrapGAppsHook4
    ];

    buildInputs = [
      dbus
      gtk4
      libadwaita
      pam
      python
    ];

    # PID 1 in the build sandbox runs as the build user.
    checkFlags = ["--skip=tty::tests::pid_1_is_not_mine"];

    postBuild = ''
      make -C pam CC="$CC"
    '';

    postInstall = ''
      install -Dm755 pam/pam_immurok.so -t $out/lib/security
      install -Dm755 scripts/immurok-auth-dialog scripts/immurok-pam-helper -t $out/bin
      install -Dm644 scripts/ble-notify-helper.py -t $out/share/immurok

      install -Dm644 packaging/immurok-daemon.service -t $out/lib/systemd/system
      install -Dm644 packaging/immurok-session-agent.service -t $out/lib/systemd/user
      install -Dm644 packaging/dbus/immurok.conf -t $out/share/dbus-1/system.d
      install -Dm644 packaging/com.immurok.Settings.service -t $out/share/dbus-1/services
      install -Dm644 packaging/polkit/49-immurok.rules -t $out/share/polkit-1/rules.d
      install -Dm644 packaging/com.immurok.Settings.desktop -t $out/share/applications
      install -Dm644 scripts/com.immurok.pam-helper.policy.in \
        $out/share/polkit-1/actions/com.immurok.pam-helper.policy

      for d in packaging/icons/hicolor/*/apps; do
        install -Dm644 $d/com.immurok.Settings.png \
          $out/share/icons/hicolor/$(basename $(dirname $d))/apps/com.immurok.Settings.png
      done

      substituteInPlace \
        $out/lib/systemd/system/immurok-daemon.service \
        $out/lib/systemd/user/immurok-session-agent.service \
        $out/share/dbus-1/services/com.immurok.Settings.service \
        --replace-fail /usr/bin $out/bin
      substituteInPlace $out/share/polkit-1/actions/com.immurok.pam-helper.policy \
        --replace-fail @HELPER_PATH@ $out/bin/immurok-pam-helper
    '';

    # The daemon runs `python3 ble-notify-helper.py` from PATH, the session
    # agent calls notify-send, and both shell out to loginctl. The BLE helper
    # stays outside bin/ and libexec/ so it is not replaced by a wrapper.
    preFixup = ''
      gappsWrapperArgs+=(
        --prefix PATH : ${lib.makeBinPath [python libnotify]}
        --suffix PATH : ${lib.makeBinPath [systemd]}
        --set-default IMMUROK_HELPER_DIR $out/share/immurok
      )
    '';

    meta = {
      description = "Linux companion app for the immurok BLE fingerprint key";
      homepage = "https://github.com/immurok/app-linux-rs";
      license = lib.licenses.asl20;
      platforms = lib.platforms.linux;
      mainProgram = "immurok-gui";
    };
  })
