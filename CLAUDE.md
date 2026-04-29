# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal `~/.config` dotfiles plus a bootstrap installer (`setup.sh`) for setting up a fresh OS. Each top-level directory (`zsh/`, `zed/`, `ghostty/`, `aerospace/`, `vivaldi/`, `git/`, `gh/`, `micro/`, `raycast/`, `cagent/`, `openspec/`) is the live config for one app and is consumed in-place from `~/.config/<app>/`.

Branches map to machines: `macos`, `cachyos-home`, `cachyos-work`. `main` is the shared base. Per-machine changes go on the machine branch — do not merge them to `main` unless they're truly cross-platform.

## Bootstrap flow

`./setup.sh` is the entry point. It cascades:

1. Top-level `setup.sh` — chmods everything 700, runs `setup/.setup.sh`, then if invoked from outside `~/.config`, copies every directory + the meta files (`setup/`, `.git/`, `setup.sh`, `README.md`, `.gitignore`) into `~/.config/`. The repo is intended to be cloned anywhere and bootstrapped from there; the real install lives in `~/.config`.
2. `setup/.setup.sh` — runs sub-modules in order defined by the `ORDER` array (currently `brew`, then `tweak`). Each module is a directory containing its own `.setup.sh`.
3. `setup/brew/.setup.sh` — installs Homebrew if missing, then iterates every `*.sh` sibling. **The filename minus `.sh` must equal the brew formula or cask name** — it's used for the `brew list` skip check (`brew list pkg || brew list --cask pkg`). If the names diverge (e.g. installing from a tap with a different cask name), the skip check breaks and the script reinstalls every run.
4. `setup/tweak/.setup.sh` — same iteration pattern, but no skip check; tweaks are expected to be idempotent (`defaults write`, `duti -s`, etc.).

Each runner captures stdout+stderr to `<script>.log` via `tee`, uses `${PIPESTATUS[0]}` to get the real exit (not `tee`'s), deletes the log on success, and aggregates a `❌ Failed: …` / `✅ Installed: …` summary at the end. Preserve this pattern when editing.

## Adding things

- **New brew package:** create `setup/brew/<pkg>.sh` containing `#!/bin/bash`, `set -e`, and `brew install <pkg>` (or `brew install --cask <pkg>`). Filename must match the package name. For tapped formulas, tap inside the script (see `bun.sh`).
- **New system tweak:** create `setup/tweak/<name>.sh`. Make it idempotent — it will run every bootstrap.
- **New app config:** create `<app>/` at the repo root and add it to `.gitignore` as `!<app>/` + `!<app>/**` (the gitignore is allowlist-style: everything is ignored, then specific paths are unignored).
- **New zsh function/alias:** drop a `<name>.zsh` file in `zsh/rc.d/`. `.zshrc` sources all of them via `for rc in "$ZDOTDIR"/rc.d/*.zsh(N); do source "$rc"; done`. Don't edit `.zshrc` itself unless you need plugin/zinit-level changes.

## zsh layout

`tweak/zsh.sh` writes `~/.zshenv` to set `ZDOTDIR=$HOME/.config/zsh`, so the entire shell config lives in this repo. `.zprofile` sets up Homebrew. `.zshrc` loads zinit, starship, autocomplete/autosuggestions/syntax-highlighting plugins (the latter two `wait lucid` for async load), zoxide as `cd`, then sources `rc.d/`. After load, it `zcompile`s itself if newer than the `.zwc`.

## Multi-account git (`zsh/rc.d/git-multi-account.zsh`)

`git` is shadowed by a function that intercepts `clone`, `submodule add`, `submodule init`, `submodule update`. It parses the GitHub URL, resolves which of two accounts (`Adrian-LSY` for rooftop.my work, `AdrianLSY` for personal) has push access via `gh api`, runs the underlying git command with `GIT_SSH_COMMAND` pointing at the right key, then stamps that account's identity + SSH-signing config (`user.email`, `user.signingkey`, `commit.gpgsign`, etc.) onto the resulting repo and every submodule. `ghs <account>` re-stamps the current repo manually.

When editing this file, keep the `command git ...` calls — bare `git` would recurse into the function. The two account names are referenced in three case statements (key, email, signingkey lookup) plus the resolution logic; update all of them together.

## Other notable bits

- `ghp "msg"`: `git add . && git commit -m "msg" && git push` (sets upstream on first push).
- `ghu`: on the current repo + every submodule in parallel, fetches origin, fast-forwards (or hard-resets) the default branch, and deletes branches whose upstreams are gone.
- `ai`: alias for `claude --dangerously-skip-permissions`.
- `aerospace/aerospace.toml` references `adrianlsy.github.io/AeroSpace` — this is a personal fork (`AdrianLSY/tap/aerospace-adrianlsy`), not the upstream `nikitabobko/AeroSpace`. Hover-to-raise (`[auto-raise]`) is fork-specific and won't work on upstream builds.
- `.gitignore` is allowlist-style (`*` then `!` exceptions). New tracked directories must be added explicitly with both `!dir/` and `!dir/**`.
