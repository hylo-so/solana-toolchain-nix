# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Nix flake that packages Anza's Solana/SBF (Solana Bytecode Format) toolchain as reproducible derivations. Extracted from a larger protocol repository so multiple projects can share the same toolchain without duplicating Nix setup.

Exports five packages and a dev shell that sets the environment variables for SBF smart contract compilation (`RUSTC`, `CC`, `AR`, `OBJDUMP`, `OBJCOPY`). The dev shell `shellHook` symlinks `platform-tools` into `~/.cache/solana/<version>/platform-tools`, the only location `cargo-build-sbf` reads it from.

## Build Commands

```bash
nix build .#platform-tools   # Rust + LLVM for SBF (v1.57)
nix build .#solana-cli        # Solana CLI tools (v4.1.2)
nix build .#cargo-build-sbf   # cargo-build-sbf and cargo-test-sbf (v4.4.0)
nix build .#anchor            # Anchor CLI (v0.32.2)
nix build .#cargo-wrapper     # cargo that drops rustup +toolchain args
nix flake check               # Validate flake syntax and evaluate packages
nix develop                   # Enter dev shell with all env vars set
```

## Architecture

- **`flake.nix`** — Entry point. Uses `flake-parts` for multi-system support (aarch64-darwin, aarch64-linux, x86_64-darwin, x86_64-linux). Defines all packages and the default dev shell.
- **`platform-tools.nix`** — Downloads pre-built Anza platform-tools binaries (Rust compiler + LLVM) per platform. Extracts `rust/` and `llvm/` directories.
- **`solana-cli.nix`** — Downloads pre-built Solana CLI release binaries per platform. Extracts `bin/` directory and removes the bundled `cargo-build-sbf` and `cargo-test-sbf`.
- **`cargo-build-sbf.nix`** — Builds `cargo-build-sbf` and `cargo-test-sbf` from the `anza-xyz/cargo-build-sbf` source. The build fails when the source's default platform-tools version differs from `platform-tools.nix`.
- **`anchor.nix`** — Overrides the nixpkgs `anchor` package with a pinned version.
- **`cargo-wrapper.nix`** — Wraps `cargo` to drop rustup `+toolchain` arguments.
- **`sbf-env-hook.sh`** — Setup hook exporting `RUSTC`, `CC`, `AR`, `OBJDUMP`, `OBJCOPY` from `platform-tools`.

`platform-tools.nix` and `solana-cli.nix` select platform-specific download URLs and SHA256 hashes, throwing an error for unsupported platforms (aarch64-linux missing for solana-cli).

## Consumer Integration

Other flakes consume this via `inputsFrom` in their `mkShell`, which merges all packages and env vars automatically:

```nix
inputs.solana-nix.url = "github:org/solana-toolchain-nix";
devShells.sbf = mkShell {
  inputsFrom = [ solana-nix.devShells.${system}.default ];
};
```

The dev shell has no `rustup`, so consumers pass `--no-rustup-override --skip-tools-install` to `cargo build-sbf` and `cargo test-sbf` themselves, for example `anchor build -- --no-rustup-override --skip-tools-install`.
