{
  description = "Solana toolchain packaged with Nix";

  inputs = {
    nixpkgs.url =
      "github:NixOS/nixpkgs/b6804236c328e245d0814167472405b35addc350";
    flake-parts.url =
      "github:hercules-ci/flake-parts/9126214d0a59633752a136528f5f3b9aa8565b7d";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems =
        [ "aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux" ];

      perSystem = { config, self', inputs', pkgs, system, ... }:
        with import nixpkgs { inherit system; };
        let
          platformTools = callPackage ./platform-tools.nix { inherit system; };
          solanaCli = callPackage ./solana-cli.nix { inherit system; };
          sbfSdk = callPackage ./sbf-sdk.nix { inherit platformTools; };
          anchor = callPackage ./anchor.nix { inherit (pkgs) anchor; };
          cargoWrapper = callPackage ./cargo-wrapper.nix { inherit (pkgs) cargo; };
          sbfEnvHook = makeSetupHook {
            name = "sbf-env-hook";
            substitutions = {
              sbfSdkPath = "${sbfSdk}";
              rustc = "${platformTools}/rust/bin/rustc";
              cc = "${platformTools}/llvm/bin/clang";
              ar = "${platformTools}/llvm/bin/llvm-ar";
              objdump = "${platformTools}/llvm/bin/llvm-objdump";
              objcopy = "${platformTools}/llvm/bin/llvm-objcopy";
            };
          } ./sbf-env-hook.sh;
        in {
          packages = {
            platform-tools = platformTools;
            solana-cli = solanaCli;
            sbf-sdk = sbfSdk;
            cargo-wrapper = cargoWrapper;
            inherit anchor;
          };

          devShells.default = mkShell {
            nativeBuildInputs = [ sbfEnvHook ];
            packages = [ solanaCli anchor cargoWrapper ];
          };
        };
    };
}
