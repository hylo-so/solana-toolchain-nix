# Builds the SBF SDK directory layout that cargo-build-sbf expects:
#   $SBF_SDK_PATH/scripts/{strip.sh,dump.sh,...}
#   $SBF_SDK_PATH/env.sh
#   $SBF_SDK_PATH/dependencies/platform-tools/{rust,llvm}
#
# Scripts come from the agave source tree (platform-tools-sdk/sbf/),
# since they aren't included in any release tarball.
{ platformTools, stdenv, fetchFromGitHub, }:
let
  agaveSrc = fetchFromGitHub {
    owner = "anza-xyz";
    repo = "agave";
    rev = "v3.1.14";
    sparseCheckout = [ "platform-tools-sdk/sbf" ];
    hash = "sha256-As22yUzo7xSGxdw+lmn6uHb1Pn5BeB1Abm9YVvabBHI=";
  };
in stdenv.mkDerivation {
  pname = "sbf-sdk";
  inherit (platformTools) version;
  dontUnpack = true;
  installPhase = ''
    cp -r ${agaveSrc}/platform-tools-sdk/sbf $out
    chmod -R u+w $out
    mkdir -p $out/dependencies
    ln -s ${platformTools} $out/dependencies/platform-tools
    printf '#!/usr/bin/env bash\nexit 0\n' > $out/scripts/install.sh
  '';
}
