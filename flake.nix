{
  description = "Solana toolchain packaged with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
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
          anchor = callPackage ./anchor.nix { inherit (pkgs) anchor; };
          cargoBuildSbf = callPackage ./cargo-build-sbf.nix { };
          cargoWrapper =
            callPackage ./cargo-wrapper.nix { inherit (pkgs) cargo; };
          sbfEnvHook = makeSetupHook {
            name = "sbf-env-hook";
            substitutions = {
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
            cargo-build-sbf = cargoBuildSbf;
            cargo-wrapper = cargoWrapper;
            inherit anchor;
          };

          devShells.default = mkShell {
            nativeBuildInputs = [ sbfEnvHook ];
            packages = [ solanaCli anchor cargoWrapper cargoBuildSbf ];
            shellHook = ''
              export PATH=${cargoBuildSbf}/bin''${PATH:+:}$PATH
              if [[ -n "''${HOME:-}" ]]; then
                tools_dest="$HOME/.cache/solana/${platformTools.version}/platform-tools"
                mkdir -p "$(dirname "$tools_dest")"
                if [[ -L "$tools_dest" || ! -e "$tools_dest" ]]; then
                  ln -sfn ${platformTools} "$tools_dest"
                fi
              fi
            '';
          };
        };
    };
}
