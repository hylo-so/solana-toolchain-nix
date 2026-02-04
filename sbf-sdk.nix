# Mimics the SBF SDK directory layout that cargo-build-sbf expects:
#   $SBF_SDK_PATH/dependencies/platform-tools/{rust,llvm}
{ platformTools, stdenv, }:
stdenv.mkDerivation {
  pname = "sbf-sdk";
  inherit (platformTools) version;
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/dependencies
    ln -s ${platformTools} $out/dependencies/platform-tools
  '';
}
