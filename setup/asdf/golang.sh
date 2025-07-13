#!/bin/bash
set -e

asdf plugin add golang
asdf install golang latest
asdf set golang latest
