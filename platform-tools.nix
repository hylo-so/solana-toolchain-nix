{ fetchurl, stdenv, system, }:
let
  version = "v1.48";

  src = {
    aarch64-darwin = fetchurl {
      url =
        "https://github.com/anza-xyz/platform-tools/releases/download/${version}/platform-tools-osx-aarch64.tar.bz2";
      hash = "sha256-eZ5M/O444icVXIP7IpT5b5SoQ9QuAcA1n7cSjiIW0t0=";
    };
    aarch64-linux = fetchurl {
      url =
        "https://github.com/anza-xyz/platform-tools/releases/download/${version}/platform-tools-linux-aarch64.tar.bz2";
      hash = "sha256-i3I9pwa+DyMJINFr+IucwytzEHdiRZU6r7xWHzppuR4=";
    };
    x86_64-linux = fetchurl {
      url =
        "https://github.com/anza-xyz/platform-tools/releases/download/${version}/platform-tools-linux-x86_64.tar.bz2";
      hash = "sha256-qdMVf5N9X2+vQyGjWoA14PgnEUpmOwFQ20kuiT7CdZc=";
    };
  }.${system} or (throw "Unsupported system: ${system}");
in stdenv.mkDerivation {
  pname = "solana-platform-tools";
  inherit version;
  inherit src;
  sourceRoot = ".";
  dontFixup = true;
  installPhase = ''
    mkdir -p $out
    cp -r rust llvm version.md $out/
  '';
}
