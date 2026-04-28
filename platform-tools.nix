{ fetchurl, stdenv, system, }:
let
  version = "v1.54";

  src = {
    aarch64-darwin = fetchurl {
      url =
        "https://github.com/anza-xyz/platform-tools/releases/download/${version}/platform-tools-osx-aarch64.tar.bz2";
      hash = "sha256-HIs69ehhThxFk5OpXFsZv7zI7ROCKhy1OfrmhHH5v7s=";
    };
    x86_64-darwin = fetchurl {
      url =
        "https://github.com/anza-xyz/platform-tools/releases/download/${version}/platform-tools-osx-x86_64.tar.bz2";
      hash = "sha256-0ctxZYkgB9Ea1y/e0Wx2km5d+p/yhv49mZRAwa80p1g=";
    };
    aarch64-linux = fetchurl {
      url =
        "https://github.com/anza-xyz/platform-tools/releases/download/${version}/platform-tools-linux-aarch64.tar.bz2";
      hash = "sha256-9igS3Za2scjg4s9ncUaRLFjIPpXXYsMOiSMNZp+cLmo=";
    };
    x86_64-linux = fetchurl {
      url =
        "https://github.com/anza-xyz/platform-tools/releases/download/${version}/platform-tools-linux-x86_64.tar.bz2";
      hash = "sha256-/MQWMcf3dWG/VBIhi/KXUB3M8DBeooDzOPCs4qq58x4=";
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
