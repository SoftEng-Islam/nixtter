{
  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-trusted-public-keys =
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = { self, nixpkgs, devenv, systems, ... }@inputs:
    let forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in {
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
        devenv-test = self.devShells.${system}.default.config.test;
      });

      devShells = forEachSystem (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [{
              # https://devenv.sh/reference/options/

              # https://devenv.sh/packages/
              packages = with pkgs; [
                glibc
                zlib
                libGL
                libpulseaudio
                stdenv.cc.cc.lib
                libglvnd
                libxkbcommon
                qt5.qtbase
                qt5.qtwayland
                xorg.libX11
                xorg.libxcb
                xorg.libXext
                xorg.libXfixes
                xorg.libXi
                xorg.libXrandr
                xorg.libXrender
                xorg.libXtst

                flutter
                jdk17 # Required for Gradle
                git
                chromium # For web development

                # Graphics dependencies
                libGL
                libglvnd
                libxkbcommon
              ];
              android = {
                enable = true;
                platforms.version = [ "34" ];
                systemImageTypes = [ "google_apis" ];
                abis = [ "x86_64" ];
                cmake.version = [ "3.22.1" ];
                cmdLineTools.version = "11.0";
                tools.version = "26.1.1";
                platformTools.version = "34.0.5";
                buildTools.version = [ "30.0.3" ];
                emulator = {
                  enable = true;
                  version = "34.1.9";
                };
                sources.enable = false;
                systemImages.enable = true;
                ndk.enable = false;
                googleAPIs.enable = true;
                googleTVAddOns.enable = false;
                extras = [ ];
                extraLicenses = [
                  "android-sdk-preview-license"
                  "android-googletv-license"
                  "android-sdk-arm-dbt-license"
                  "google-gdk-license"
                  "intel-android-extra-license"
                  "intel-android-sysimage-license"
                  "mips-android-sysimage-license"
                ];
                android-studio = {
                  enable = false;
                  package = pkgs.android-studio;
                };
                flutter.enable = true;
              };

              # https://devenv.sh/basics/
              env.GREET = "devenv";

              # https://devenv.sh/scripts/
              scripts.hello.exec = "echo hello from $GREET";

              enterShell = ''
                hello
                git --version
                export CHROME_EXECUTABLE=$(which chromium)
                export ANDROID_HOME=$(which android | sed -E 's/(.*libexec\/android-sdk).*/\1/')
                export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH

                # Qt platform plugin fix
                export QT_QPA_PLATFORM_PLUGIN_PATH=${pkgs.libsForQt5.qt5.qtbase}/lib/qt-5.15.16/plugins/platforms
                export QT_PLUGIN_PATH=$(dirname "$QT_QPA_PLATFORM_PLUGIN_PATH")

                # Create a symbolic link to the '8.0' directory named 'latest' if it doesn't exist
                # I added this link in to stop `flutter doctor` complaining - not that it matters really
                # It doesn't seem to be required currently - so I commented it out
                #  if [ ! -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
                #    ln -s $ANDROID_HOME/cmdline-tools/8.0 $ANDROID_HOME/cmdline-tools/latest
                #  fi
              '';

              # https://devenv.sh/tests/
              enterTest = ''
                echo "Running tests"
                git --version | grep "2.42.0"
              '';

              # https://devenv.sh/services/
              # services.postgres.enable = true;

              # https://devenv.sh/languages/
              # languages.nix.enable = true;

              # https://devenv.sh/pre-commit-hooks/
              # pre-commit.hooks.shellcheck.enable = true;

              # https://devenv.sh/processes/
              # processes.ping.exec = "ping example.com";

              # See full reference at https://devenv.sh/reference/options/
            }];
          };
        });
    };
}
