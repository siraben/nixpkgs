{
  mkKdeDerivation,
  qtbase,
  libsForQt5,
}:
mkKdeDerivation {
  pname = "oxygen";

  outputs = [
    "out"
    "dev"
    "qt5"
  ];

  # We can't add qt5 stuff to dependencies or the hooks blow up,
  # so manually point everything to everything. Oof.
  extraCmakeFlags = [
    "-DQt5_DIR=${libsForQt5.qtbase.dev}/lib/cmake/Qt5"
    "-DQt5Core_DIR=${libsForQt5.qtbase.dev}/lib/cmake/Qt5Core"
    "-DQt5DBus_DIR=${libsForQt5.qtbase.dev}/lib/cmake/Qt5DBus"
    "-DQt5Gui_DIR=${libsForQt5.qtbase.dev}/lib/cmake/Qt5Gui"
    "-DQt5Network_DIR=${libsForQt5.qtbase.dev}/lib/cmake/Qt5Network"
    "-DQt5Qml_DIR=${libsForQt5.qtdeclarative.dev}/lib/cmake/Qt5Qml"
    "-DQt5QmlModels_DIR=${libsForQt5.qtdeclarative.dev}/lib/cmake/Qt5QmlModels"
    "-DQt5Quick_DIR=${libsForQt5.qtdeclarative.dev}/lib/cmake/Qt5Quick"
    "-DQt5Widgets_DIR=${libsForQt5.qtbase.dev}/lib/cmake/Qt5Widgets"
    "-DQt5X11Extras_DIR=${libsForQt5.qtx11extras.dev}/lib/cmake/Qt5X11Extras"
    "-DQt5Xml_DIR=${libsForQt5.qtbase.dev}/lib/cmake/Qt5Xml"

    "-DKF5Auth_DIR=${libsForQt5.__internalKF5.kauth.dev}/lib/cmake/KF5Auth"
    "-DKF5Codecs_DIR=${libsForQt5.__internalKF5.kcodecs.dev}/lib/cmake/KF5Codecs"
    "-DKF5Config_DIR=${libsForQt5.__internalKF5.kconfig.dev}/lib/cmake/KF5Config"
    "-DKF5ConfigWidgets_DIR=${libsForQt5.__internalKF5.kconfigwidgets.dev}/lib/cmake/KF5ConfigWidgets"
    "-DKF5Completion_DIR=${libsForQt5.__internalKF5.kcompletion.dev}/lib/cmake/KF5Completion"
    "-DKF5CoreAddons_DIR=${libsForQt5.__internalKF5.kcoreaddons.dev}/lib/cmake/KF5CoreAddons"
    "-DKF5FrameworkIntegration_DIR=${libsForQt5.__internalKF5.frameworkintegration.dev}/lib/cmake/KF5FrameworkIntegration"
    "-DKF5GuiAddons_DIR=${libsForQt5.__internalKF5.kguiaddons.dev}/lib/cmake/KF5GuiAddons"
    "-DKF5IconThemes_DIR=${libsForQt5.__internalKF5.kiconthemes.dev}/lib/cmake/KF5IconThemes"
    "-DKF5I18n_DIR=${libsForQt5.__internalKF5.ki18n.dev}/lib/cmake/KF5I18n"
    "-DKF5Kirigami2_DIR=${libsForQt5.__internalKF5.kirigami2.dev}/lib/cmake/KF5Kirigami2"
    "-DKF5Service_DIR=${libsForQt5.__internalKF5.kservice.dev}/lib/cmake/KF5Service"
    "-DKF5WidgetsAddons_DIR=${libsForQt5.__internalKF5.kwidgetsaddons.dev}/lib/cmake/KF5WidgetsAddons"
    "-DKF5WindowSystem_DIR=${libsForQt5.__internalKF5.kwindowsystem.dev}/lib/cmake/KF5WindowSystem"
  ];

  # The Qt5 libraries are moved to their own output before RPATH fixups. Add
  # that location while linking; patchELF removes it from Qt6 binaries as unused.
  preConfigure = ''
    appendToVar NIX_LDFLAGS "-rpath $qt5/lib"
  '';

  # Move Qt5 plugin to Qt5 plugin path
  postInstall = ''
    mkdir -p $qt5/${libsForQt5.qtbase.qtPluginPrefix}/styles
    mv $out/${qtbase.qtPluginPrefix}/styles/oxygen5.so $qt5/${libsForQt5.qtbase.qtPluginPrefix}/styles

    moveToOutput bin/oxygen-demo5 $qt5
    moveToOutput 'lib/liboxygenstyle5*' $qt5
    moveToOutput 'lib/liboxygenstyleconfig5*' $qt5
  '';

  installCheckPhase = ''
    runHook preInstallCheck

    checkElfDeps() {
      local dependencies
      dependencies="$(ldd "$1")"
      if grep -Fq 'not found' <<< "$dependencies"; then
        printf '%s\n' "$dependencies" >&2
        echo "unresolved shared-library dependency in $1" >&2
        return 1
      fi
    }

    plugin="$qt5/${libsForQt5.qtbase.qtPluginPrefix}/styles/oxygen5.so"
    demo="$qt5/bin/.oxygen-demo5-wrapped"

    patchelf --print-needed "$plugin" | grep -Fx 'liboxygenstyle5.so.6'
    ldd "$plugin" | grep -F "$qt5/lib/liboxygenstyle5.so.6"

    checkElfDeps "$plugin"
    checkElfDeps "$demo"
    checkElfDeps "$qt5/lib/liboxygenstyleconfig5.so.6"

    runHook postInstallCheck
  '';
}
