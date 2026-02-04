{ anchor, fetchFromGitHub, rustPlatform, pkg-config, openssl, lib, stdenv
, udev, }:
anchor.overrideAttrs (old: rec {
  version = "0.32.1";
  src = fetchFromGitHub {
    owner = "coral-xyz";
    repo = "anchor";
    tag = "v${version}";
    hash = "sha256-oyCe8STDciRtdhOWgJrT+k50HhUWL2LSG8m4Ewnu2dc=";
    fetchSubmodules = true;
  };
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    name = "anchor-${version}-vendor";
    hash = "sha256-XrVvhJ1lFLBA+DwWgTV34jufrcjszpbCgXpF+TUoEvo=";
  };
  OPENSSL_NO_VENDOR = "1";
  nativeBuildInputs = old.nativeBuildInputs ++ [ pkg-config ];
  buildInputs = old.buildInputs ++ [ openssl ]
    ++ lib.optionals stdenv.isLinux [ udev ];
})
