#!/bin/bash
set -e

# Counterpart of macos/setup/brew/ruby.sh (brew ruby is 4.0.x). The DevKit
# variant bundles the MSYS2 toolchain needed to build native gems — matching
# what brew's ruby can do out of the box. Version-pinned id: when brew's ruby
# moves major.minor, bump this filename + id together.
winget install --id "RubyInstallerTeam.RubyWithDevKit.4.0" -e --accept-package-agreements --accept-source-agreements
