#!/bin/bash
set -e

# erlang is needs to be installed to compile elixir
asdf plugin add erlang
asdf install erlang latest
asdf set erlang latest

asdf plugin add elixir
asdf install elixir latest
asdf set elixir latest
