#!/bin/bash
set -e

defaults write com.apple.Finder AppleShowAllFiles true
killall Finder
