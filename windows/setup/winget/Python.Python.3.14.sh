#!/bin/bash
set -e

# Counterpart of macos/setup/brew/python.sh (brew `python` -> python@3.14).
# winget pins the minor version in the id: when brew's alias moves, bump this
# filename + id together (filename must stay equal to the winget id).
winget install --id "Python.Python.3.14" -e --accept-package-agreements --accept-source-agreements
