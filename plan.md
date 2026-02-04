# Extracting SBF Nix Setup Into Its Own Repository

## What Needs to Move

3 files from `nix/` plus the SBF dev shell definition:

| File | Purpose |
|------|---------|
| `nix/platform-tools.nix` | Downloads Anza platform-tools (Rust + LLVM for SBF) v1.48 |
| `nix/sbf-sdk.nix` | Creates `$SBF_SDK_PATH/dependencies/platform-tools/` symlink layout |
| `nix/solana-cli.nix` | Downloads Solana CLI v2.3.13 from Anza/Agave |

Currently consumed in `flake.nix:26-29` to build derivations, and `flake.nix:66-79` for the `devShells.sbf` shell with env vars (`SBF_SDK_PATH`, `RUSTC`, `CC`, `AR`, `OBJDUMP`, `OBJCOPY`).

## New Repository

The new repo exports a **dev shell** so consumers get the full SBF environment (env vars, hooks, binaries) without duplicating setup:

```
solana-nix/
  flake.nix
  nix/
    platform-tools.nix   # copied from protocol
    sbf-sdk.nix           # copied from protocol
    solana-cli.nix        # copied from protocol
```

### New `flake.nix`

```nix
{
  description = "Solana SBF toolchain for Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/<same-pin>";
    flake-parts.url = "github:hercules-ci/flake-parts/<same-pin>";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux" ];

      perSystem = { config, self', inputs', pkgs, system, ... }:
        with import nixpkgs { inherit system; };
        let
          platformTools = callPackage ./nix/platform-tools.nix { inherit system; };
          solanaCli = callPackage ./nix/solana-cli.nix { inherit system; };
          sbfSdk = callPackage ./nix/sbf-sdk.nix { inherit platformTools; };
        in {
          # Export individual packages for flexibility
          packages = {
            platform-tools = platformTools;
            solana-cli = solanaCli;
            sbf-sdk = sbfSdk;
          };

          # Export a ready-to-use dev shell with all env vars set
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
```

Key points:
- Exports both `packages` (for cherry-picking) and `devShells.default` (for full shell)
- The shell includes `solanaCli` in `packages` and all SBF env vars
- `anchor` is **not** included here — it stays in protocol since it's protocol-specific

## Changes to Protocol `flake.nix`

### 1. Add input

```nix
inputs = {
  # ... existing ...
  solana-nix.url = "github:your-org/solana-nix";
  solana-nix.inputs.nixpkgs.follows = "nixpkgs";  # avoid duplicate nixpkgs
};
```

### 2. Use the imported shell via `inputsFrom`

The `inputsFrom` mechanism in `mkShell` merges another shell's packages and env vars into the current one:

```nix
devShells.sbf = mkShell {
  inputsFrom = [ solana-nix.devShells.${system}.default ];
  packages = [ anchor ];

  buildInputs = sharedBuildInputs;
  CARGO_FEATURE_NO_NEON = "true";
  ANCHOR_WALLET = "./dev-wallet.json";
};
```

This pulls in `solanaCli`, `SBF_SDK_PATH`, `RUSTC`, `CC`, `AR`, `OBJDUMP`, `OBJCOPY` from the imported shell automatically.

For `devShells.default`, replace the local `solanaCli` reference:

```nix
devShells.default = mkShell {
  packages = [
    rust
    solana-nix.packages.${system}.solana-cli  # was: solanaCli
    anchor
    # ... rest unchanged ...
  ];
  # ...
};
```

### 3. Delete `nix/` directory

Remove `nix/platform-tools.nix`, `nix/sbf-sdk.nix`, `nix/solana-cli.nix`.

### 4. Remove local derivation definitions

Delete lines 26-29 from `flake.nix`:
```nix
# DELETE these:
platformTools = callPackage ./nix/platform-tools.nix { inherit system; };
solanaCli = callPackage ./nix/solana-cli.nix { inherit system; };
sbfSdk = callPackage ./nix/sbf-sdk.nix { inherit platformTools; };
```

### 5. Lock the new input

```bash
nix flake lock --update-input solana-nix
```

## What Stays in Protocol

- `devShells.sbf` definition (uses `inputsFrom` to pull in the SBF shell)
- `devShells.default` (references `solana-cli` package from new input)
- `anchor` in both shells
- `CARGO_FEATURE_NO_NEON`, `ANCHOR_WALLET` env vars
- Everything else (Rust toolchain, Node/pnpm, hylo-tools, nightly shell)

## Verification

1. `nix flake check` in both repos
2. `nix develop .#sbf` in protocol — verify env vars:
   - `echo $SBF_SDK_PATH` points to valid path
   - `$RUSTC --version` returns the platform-tools Rust
   - `$CC --version` returns platform-tools clang
   - `solana --version` returns 2.3.13
3. `nix develop` (default shell) — verify `solana --version` still works
4. `./bin/build.sh` succeeds
5. `anchor run cargo-test` passes
