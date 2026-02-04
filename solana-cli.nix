{ fetchurl, stdenv, system, }:
let
  version = "2.3.13";

  src = {
    aarch64-darwin = fetchurl {
      url =
        "https://github.com/anza-xyz/agave/releases/download/v${version}/solana-release-aarch64-apple-darwin.tar.bz2";
      hash = "sha256-sgRfLCyoyXuCczutpsnBG0YZbBrNjwDjN0Kn0sIGChI=";
    };
    x86_64-darwin = fetchurl {
      url =
        "https://github.com/anza-xyz/agave/releases/download/v${version}/solana-release-x86_64-apple-darwin.tar.bz2";
      hash = "sha256-fuJa2McNlzcir5KCbBG3Ne99ud21kmfMAYFzTaUKLa8=";
    };
    x86_64-linux = fetchurl {
      url =
        "https://github.com/anza-xyz/agave/releases/download/v${version}/solana-release-x86_64-unknown-linux-gnu.tar.bz2";
      hash = "sha256-3F9bt0RlVEcFZLLYofGyH+KIw5Z/WbV9Y2UOQdNY7bs=";
    };
  }.${system} or (throw "Unsupported system: ${system}");
in stdenv.mkDerivation {
  pname = "solana-cli";
  inherit version;
  inherit src;
  sourceRoot = "solana-release";
  dontFixup = true;
  installPhase = ''
    mkdir -p $out
    cp -r bin $out/
  '';
}
