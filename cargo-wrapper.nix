# Wraps cargo to strip rustup +toolchain args (e.g. `cargo +stable test`).
# Anchor's IDL build invokes `cargo +stable test` but nix-provided cargo
# is not a rustup proxy and does not understand toolchain selectors.
{ writeShellApplication, cargo }:
writeShellApplication {
  name = "cargo";
  text = ''
    args=()
    for arg in "$@"; do
      case "$arg" in
        +*) ;;
        *) args+=("$arg") ;;
      esac
    done
    exec ${cargo}/bin/cargo "''${args[@]}"
  '';
}
