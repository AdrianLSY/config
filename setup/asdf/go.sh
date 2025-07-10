#!/bin/bash
set -e

asdf plugin add go
asdf install go latest
asdf set go latest
