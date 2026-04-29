{ anchor, fetchFromGitHub, rustPlatform, pkg-config, openssl, lib, stdenv
, udev, }:
anchor.overrideAttrs (old: rec {
  version = "1.0.1";
  src = fetchFromGitHub {
    owner = "coral-xyz";
    repo = "anchor";
    tag = "v${version}";
    hash = "sha256-lpLNocNrSWkf/b34PCmUKqFumdo3LcOyGMtN8O2ciEU=";
    fetchSubmodules = true;
  };
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    name = "anchor-${version}-vendor";
    hash = "sha256-Nx5g+X9cPL71Gf9J/Zp5u6H8rrbDQW6KqTc/Ti+mzow=";
  };
  OPENSSL_NO_VENDOR = "1";
  nativeBuildInputs = old.nativeBuildInputs ++ [ pkg-config ];
  buildInputs = old.buildInputs ++ [ openssl ]
    ++ lib.optionals stdenv.isLinux [ udev ];
})
