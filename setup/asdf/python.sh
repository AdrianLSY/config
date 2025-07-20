#!/bin/bash
set -e

asdf plugin add python
asdf install python latest
asdf set python system
