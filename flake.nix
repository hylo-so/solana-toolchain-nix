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
        with import nixpkgs { inherit system; }; {
          packages = {
            platform-tools =
              callPackage ./nix/platform-tools.nix { inherit system; };
            solana-cli = callPackage ./nix/solana-cli.nix { inherit system; };
            sbf-sdk = callPackage ./nix/sbf-sdk.nix { inherit platformTools; };
          };

          devShells.default = mkShell {
            packages = [ solanaCli ];

            SBF_SDK_PATH = "${sbfSdk}";
            RUSTC = "${platformTools}/rust/bin/rustc";
            CC = "${platformTools}/llvm/bin/clang";
            AR = "${platformTools}/llvm/bin/llvm-ar";
            OBJDUMP = "${platformTools}/llvm/bin/llvm-objdump";
            OBJCOPY = "${platformTools}/llvm/bin/llvm-objcopy";
          };
        };
    };
}
