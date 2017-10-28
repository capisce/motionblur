{ nixpkgs ? import <nixpkgs> {}  }:
let
    inherit (nixpkgs) stdenv qt5;
    version = "2017.10.28";

in with qt5; stdenv.mkDerivation {
    name = "motionblur-${version}";
    src = ./.;
    buildInputs = [ qtbase qtdeclarative ];
    nativeBuildInputs = [ qmake ];
    installPhase = ''
        runHook preInstall
        ls -alF
        mkdir -p "$out/bin"
        cp -pr motionblur "$out/bin"
        runHook postInstall
    '';
}
