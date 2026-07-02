#!/bin/bash
set -e

# Counterpart of macos/setup/brew/rust.sh. Deliberate divergence: brew installs
# the bare toolchain, but on Windows rustup is rust-lang's supported installer
# (the standalone Rustlang.Rust.MSVC needs VS Build Tools preinstalled either
# way, and can't update itself). rustup installs the default stable toolchain.
winget install --id "Rustlang.Rustup" -e --accept-package-agreements --accept-source-agreements
