{ platformTools, rustPlatform, fetchFromGitHub, writeShellScriptBin
, symlinkJoin, }:
let
  version = "4.4.0";
  unwrapped = rustPlatform.buildRustPackage {
    pname = "cargo-build-sbf-unwrapped";
    inherit version;

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

    cargoBuildFlags = [ "-p" "cargo-build-sbf" ];
    doCheck = false;
  };

  wrap = name:
    writeShellScriptBin name ''
      extra=()
      has_skip=0
      has_no_rustup=0
      for arg in "$@"; do
        case "$arg" in
          --skip-tools-install) has_skip=1 ;;
          --no-rustup-override) has_no_rustup=1 ;;
        esac
      done
      if [[ $has_skip -eq 0 ]]; then
        extra+=(--skip-tools-install)
      fi
      if [[ $has_no_rustup -eq 0 ]]; then
        extra+=(--no-rustup-override)
      fi
      exec ${unwrapped}/bin/${name} "''${extra[@]}" "$@"
    '';
in symlinkJoin {
  name = "cargo-build-sbf-${version}";
  paths = [ (wrap "cargo-build-sbf") (wrap "cargo-test-sbf") ];
}
