#!/bin/bash
set -e

# Counterpart of macos/setup/brew/openjdk.sh. Brew's `openjdk` tracks the latest
# GA JDK (currently 26); Microsoft.OpenJDK only ships select/LTS majors, so use
# Adoptium Temurin. Version-pinned id: when brew's openjdk moves to a new major,
# bump this filename + id together (filename must stay equal to the winget id).
winget install --id "EclipseAdoptium.Temurin.26.JDK" -e --accept-package-agreements --accept-source-agreements
