{ fetchurl, stdenv, system, }:
let
  version = "v1.57";

  src = {
    aarch64-darwin = fetchurl {
      url =
        "https://github.com/anza-xyz/platform-tools/releases/download/${version}/platform-tools-osx-aarch64.tar.bz2";
      hash = "sha256-SMMsLsOsNym1yvH91sQUVJYSXt8EOyZisFhr+8kys0o=";
    };
    x86_64-darwin = fetchurl {
      url =
        "https://github.com/anza-xyz/platform-tools/releases/download/${version}/platform-tools-osx-x86_64.tar.bz2";
      hash = "sha256-5vYjGxSeZK1swSYF0PmTQFzlWGKqREBsAjVjFZ+MPK8=";
    };
    aarch64-linux = fetchurl {
      url =
        "https://github.com/anza-xyz/platform-tools/releases/download/${version}/platform-tools-linux-aarch64.tar.bz2";
      hash = "sha256-8vMckyXLLQAkTfI7ShoJBOUYGc7EnTkjWj7T7iMgN10=";
    };
    x86_64-linux = fetchurl {
      url =
        "https://github.com/anza-xyz/platform-tools/releases/download/${version}/platform-tools-linux-x86_64.tar.bz2";
      hash = "sha256-sPevEErfcm//KmoJ6i6y8tKWXJIpX01ziMCNFA4MKwA=";
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
