{ anchor, fetchFromGitHub, rustPlatform, pkg-config, openssl, lib, stdenv
, udev, }:
anchor.overrideAttrs (old: rec {
  version = "0.32.2";
  src = fetchFromGitHub {
    owner = "coral-xyz";
    repo = "anchor";
    tag = "v${version}";
    hash = "sha256-Wl2FZr4AFxUPJBOBj86Crpe97CNBjO1viCtEg35WpVc=";
    fetchSubmodules = true;
  };
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    name = "anchor-${version}-vendor";
    hash = "sha256-bSCxqy1oUxXPubY75EFJ9TXQd6VKBAxedmsvDZq65TY=";
  };
  OPENSSL_NO_VENDOR = "1";
  nativeBuildInputs = old.nativeBuildInputs ++ [ pkg-config ];
  buildInputs = old.buildInputs ++ [ openssl ]
    ++ lib.optionals stdenv.isLinux [ udev ];
})
