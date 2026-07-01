#!/bin/bash
set -e

uv tool install graphifyy

# graphify hook install / git config both act on the current repo, so cd in.
# Resolve the launcher explicitly since ~/.local/bin may not be on PATH yet.
cd "$HOME/.config"
graphify_bin="$(command -v graphify || echo "$HOME/.local/bin/graphify")"

# Auto-rebuild the knowledge graph after every commit and branch switch
# (AST-only: code + markdown structure, no LLM / no API cost). Git hooks live in
# .git/hooks and are NOT version-controlled, so this has to run per machine at
# bootstrap. Idempotent — re-running just reports "already installed".
"$graphify_bin" hook install

# graphify-out/graph.json is tracked (see .gitattributes) so the graph travels
# with the repo. Register the union merge-driver so rebuilds on different
# machines compose instead of conflicting. .git/config is not version-controlled,
# so this also has to run per machine at bootstrap.
git config merge.graphify.name "graphify graph.json union merge"
git config merge.graphify.driver "$graphify_bin merge-driver %O %A %B"
