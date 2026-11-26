{ platformTools, rustPlatform, fetchFromGitHub, pkg-config, openssl, }:
rustPlatform.buildRustPackage rec {
  pname = "cargo-build-sbf";
  version = "4.4.0";

  src = fetchFromGitHub {
    owner = "anza-xyz";
    repo = "cargo-build-sbf";
    tag = "cargo-build-sbf@v${version}";
    hash = "sha256-i7tkUE0MUTgjtwx0LeSw5bohhkTwJNEIPsOk4NBKeac=";
  };

  cargoHash = "sha256-2SiTdgBUmnvpMnxif+1TKvZLvraYQGKTQ3B3FqNvOoQ=";

  postPatch = ''
    grep --quiet --fixed-strings \
      'DEFAULT_PLATFORM_TOOLS_VERSION: &str = "${platformTools.version}"' \
      cargo-build-sbf/src/toolchain.rs || {
      echo "cargo-build-sbf ${version} does not default to" \
        "platform-tools ${platformTools.version}" >&2
      exit 1
    }
  '';

  OPENSSL_NO_VENDOR = "1";
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  cargoBuildFlags = [ "-p" "cargo-build-sbf" ];
  doCheck = false;
}
