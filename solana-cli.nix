{ fetchurl, lib, stdenv, system, autoPatchelfHook, openssl
, udev ? null }:
let
  version = "3.1.14";

  src = {
    aarch64-darwin = fetchurl {
      url =
        "https://github.com/anza-xyz/agave/releases/download/v${version}/solana-release-aarch64-apple-darwin.tar.bz2";
      hash = "sha256-VM/CaAvWQm/aBGGe4Bkz9ApknIBW86Ybog3FTdQn6+0=";
    };
    x86_64-darwin = fetchurl {
      url =
        "https://github.com/anza-xyz/agave/releases/download/v${version}/solana-release-x86_64-apple-darwin.tar.bz2";
      hash = "sha256-43aO0B2qHjz8Aq8+PrOWzsLUipns+AzV173/UQ+AjR8=";
    };
    x86_64-linux = fetchurl {
      url =
        "https://github.com/anza-xyz/agave/releases/download/v${version}/solana-release-x86_64-unknown-linux-gnu.tar.bz2";
      hash = "sha256-Bvl8BlzJd8vsLxP/ybydO5L+9IVDH8s3Ciad5pUy71E=";
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
