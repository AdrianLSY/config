#!/bin/bash
set -e

# adrianlsy/tap is my own non-official tap. Newer Homebrew treats every
# non-official tap as "untrusted" by default and refuses to load its casks,
# which breaks both the install and the runner's `brew list` skip-check.
# Trusting my own tap is unconditionally safe; tap + trust (idempotent) so the
# cask resolves by name. After the first run the skip-check in ../.setup.sh
# matches `aerospace-adrianlsy` and stops reinstalling every bootstrap.
brew tap adrianlsy/tap
brew trust --tap adrianlsy/tap

brew install --cask AdrianLSY/tap/aerospace-adrianlsy
