#!/bin/bash
set -e

# Wire the gitleaks secret-scanning tripwire (.pre-commit-config.yaml) into this repo's
# git hooks. The brew module runs first, so `pre-commit` is already installed by now.
# Idempotent: `pre-commit install` just (re)writes .git/hooks/pre-commit.
if command -v pre-commit >/dev/null 2>&1 && [ -d "$HOME/.config/.git" ]; then
    (cd "$HOME/.config" && pre-commit install)
fi
