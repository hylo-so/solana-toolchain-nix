# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Nix flake that packages Anza's Solana/SBF (Solana Bytecode Format) toolchain as reproducible derivations. Extracted from a larger protocol repository so multiple projects can share the same toolchain without duplicating Nix setup.

Exports three packages and a dev shell that sets all required environment variables for SBF smart contract compilation (`SBF_SDK_PATH`, `RUSTC`, `CC`, `AR`, `OBJDUMP`, `OBJCOPY`).

## Build Commands

```bash
nix build .#platform-tools   # Rust + LLVM for SBF (v1.48)
nix build .#solana-cli        # Solana CLI tools (v2.3.13)
nix build .#sbf-sdk           # SBF SDK directory layout
nix flake check               # Validate flake syntax and evaluate packages
nix develop                   # Enter dev shell with all env vars set
```

## Architecture

- **`flake.nix`** — Entry point. Uses `flake-parts` for multi-system support (aarch64-darwin, aarch64-linux, x86_64-darwin, x86_64-linux). Defines all three packages and the default dev shell.
- **`platform-tools.nix`** — Downloads pre-built Anza platform-tools binaries (Rust compiler + LLVM) per platform. Extracts `rust/` and `llvm/` directories.
- **`solana-cli.nix`** — Downloads pre-built Solana CLI release binaries per platform. Extracts `bin/` directory.
- **`sbf-sdk.nix`** — Creates the directory layout expected by `cargo-build-sbf`: symlinks `platform-tools` into `$out/dependencies/platform-tools/`.

Each `.nix` derivation file selects platform-specific download URLs and SHA256 hashes, throwing an error for unsupported platforms (x86_64-darwin missing for platform-tools, aarch64-linux missing for solana-cli).

## Consumer Integration

Other flakes consume this via `inputsFrom` in their `mkShell`, which merges all packages and env vars automatically:

```nix
inputs.solana-nix.url = "github:org/solana-toolchain-nix";
devShells.sbf = mkShell {
  inputsFrom = [ solana-nix.devShells.${system}.default ];
};
```
