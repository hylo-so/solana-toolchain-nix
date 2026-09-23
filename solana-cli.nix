{ fetchurl, lib, stdenv, system, autoPatchelfHook, openssl
, udev ? null }:
let
  version = "4.1.2";

  src = {
    aarch64-darwin = fetchurl {
      url =
        "https://github.com/anza-xyz/agave/releases/download/v${version}/solana-release-aarch64-apple-darwin.tar.bz2";
      hash = "sha256-UaRDGOb7i+DPppzf2zJS9MdqXrKGZ0BpTpHePS/Fp1s=";
    };
    x86_64-darwin = fetchurl {
      url =
        "https://github.com/anza-xyz/agave/releases/download/v${version}/solana-release-x86_64-apple-darwin.tar.bz2";
      hash = "sha256-62eP5QXKRw1LR0oKkqHW3WwAyV30fuTYygcS/nqX76E=";
    };
    x86_64-linux = fetchurl {
      url =
        "https://github.com/anza-xyz/agave/releases/download/v${version}/solana-release-x86_64-unknown-linux-gnu.tar.bz2";
      hash = "sha256-WZHQJ6aG60GacJpHkXizPrg1Aeiiv79ZmoGihr/L93A=";
    };
  }.${system} or (throw "Unsupported system: ${system}");
in stdenv.mkDerivation {
  pname = "solana-cli";
  inherit version;
  inherit src;
  sourceRoot = "solana-release";
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];
  buildInputs = [ openssl ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      stdenv.cc.cc.lib
      udev
    ];
  autoPatchelfIgnoreMissingDeps = [
    "libsgx_uae_service.so"
    "libsgx_urts.so"
    "libOpenCL.so.1"
  ];
  dontStrip = true;
  installPhase = ''
    mkdir -p $out
    cp -r bin $out/
  '';
  postFixup = lib.optionalString stdenv.hostPlatform.isDarwin ''
    for f in $out/bin/*; do
      if [ -f "$f" ] && otool -L "$f" 2>/dev/null | grep -q homebrew; then
        install_name_tool \
          -change /opt/homebrew/opt/openssl@3/lib/libssl.3.dylib \
                  ${openssl.out}/lib/libssl.dylib \
          -change /opt/homebrew/opt/openssl@3/lib/libcrypto.3.dylib \
                  ${openssl.out}/lib/libcrypto.dylib \
          "$f"
        /usr/bin/codesign --force --sign - "$f"
      fi
    done
  '';
}
