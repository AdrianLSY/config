# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles plus a bootstrap installer (`setup.sh`) for setting up a fresh machine on **macOS or Linux**. The repo lives at an **external** path (canonically `~/.dotfiles`), **not** at `~/.config` — `setup.sh` deploys config *into* `~/.config` by per-app **symlink** (`~/.config/<app>` → `~/.dotfiles/<tier>/<app>`), so editing through the symlink is still a repo edit.

Content is split into two OS **tiers**:

- `macos/` — the macOS machine's world: app configs (`zsh/`, `zed/`, `ghostty/`, `aerospace/`, `linearmouse/`, `vivaldi/`, `bin/`, `micro/`, `starship.toml`) **and** its own `setup/` (`brew`, `tweak`).
- `linux/` — the Linux (Arch/CachyOS) machine's world: app configs (`fish/`, `hypr/`, `waybar/`, `kitty/`, `mako/`, `rofi/`, `swaylock/`, `nvim/`, `btop/`, `tmux/`, `gtk-3.0/`, `gtk-4.0/`, `qt5ct/`, `qt6ct/`, `zed/`, `micro/`, `mimeapps.list`) **and** its own `setup/` (`pacman`, `yay`, `flatpak`, `app`, `asdf`, `tweak`).

`lib/link.sh` is the shared symlink helper (bootstrap *code*, not config). Repo meta lives at the root and is **never** symlinked into `~/.config`: `setup.sh`, `README.md`, `CLAUDE.md`, `.gitignore`, `.claude/`, `openspec/`, `graphify-out/`, `SECURE_BOOT.md`, `.gitattributes`, `.pre-commit-config.yaml`.

**Branches:** a **single branch** now carries both machines; OS is chosen at **runtime** via `uname -s`, not by a branch checkout. (This retired the old branch-per-OS model where `main` = macOS and `cachyos-home` = Linux, which carried a "never merge wholesale" footgun — impossible now that OS-specific files live in disjoint tier dirs.)

## Design decision: two tiers, no shared config tier

There is intentionally **no `common/`/`shared/` config tier**. Genuinely-shared config is duplicated per tier: `micro/` is byte-identical in both; `zed/` is duplicated with a per-tier `settings.json` (they diverge). A change to a shared file must be made in both tiers. The sanctioned escape hatch if this ever stings is a single **intra-repo, tier-to-tier symlink** (e.g. `linux/micro` → `../macos/micro`) — **not** a new `common/` tier.

## Bootstrap flow

`./setup.sh` is the entry point. Clone the repo anywhere (canonically `~/.dotfiles`) and run it — there is no in-place/skip case; it always deploys by symlink. It cascades:

1. **Top-level `setup.sh`** (the dispatcher) — refuses to run as root; detects the OS via `uname -s` → tier (`macos`|`linux`); runs a **repo-scoped** `chmod 700` (a `find` over the repo that **prunes `.git`**, never touching `~/.config`); on macOS **ensures Command Line Tools**; then sources `lib/link.sh` and calls `deploy_tier "$TIER_DIR" "$HOME/.config"` to symlink the tier's app dirs into `~/.config`; then runs `<tier>/setup/.setup.sh` capturing the real status through the `tee` pipe (guarded by `if` so `set -euo pipefail` can't abort before `${PIPESTATUS[0]}` is read) and exits with that true status.
2. **`<tier>/setup/.setup.sh`** — runs sub-modules in the order declared by its own `ORDER` array. macOS: `brew` then `tweak`. Linux: `pacman`, `yay`, `flatpak`, `app`, `asdf`, then `tweak`. Each module is a directory with its own `.setup.sh`.
3. **`<tier>/setup/<pkgmgr>/.setup.sh`** — iterates its sibling `*.sh` scripts. For the name-based skip-checks (brew, pacman, yay), **the filename minus `.sh` must equal the package's leaf name** so `brew list` / `pacman -Q` / `yay -Q` recognizes an already-installed package and doesn't reinstall it.
4. **`<tier>/setup/tweak/.setup.sh`** — same iteration, no skip-check; tweaks must be idempotent (`defaults write`, `duti -s` on macOS; `systemctl`, `ufw`, etc. on Linux).

Each runner captures stdout+stderr to `<script>.log` via `tee`, uses `${PIPESTATUS[0]}` for the real exit (not `tee`'s), deletes the log on success, retains it on failure, and prints an aggregate `❌ Failed: …` / `✅ Installed: …` summary. **Preserve this pattern when editing.**

## Symlink deploy (`lib/link.sh` → `deploy_tier`)

`deploy_tier <tier_dir> <target_dir>` enumerates the **direct children** of the tier dir, skipping the reserved `setup/` dir, and for each app dir/file applies **backup-then-link**:

- already the correct symlink → **no-op** (idempotent; creates no backup);
- exists as a real dir/file, a foreign symlink, or a broken symlink → `mv` to `<dst>.bak.<timestamp>` (with a numeric suffix if that name is taken), then symlink;
- absent → symlink.

It is **non-destructive** (never `rm -rf` a real target) and **never touches unmanaged `~/.config` entries** (it only iterates tier entries, so `gh/`, `uv/`, `raycast/`, etc. are left alone). Rollback is per-app: remove the symlink, restore its `.bak.<ts>`.

## Adding things

- **New package:** create `<tier>/setup/<pkgmgr>/<pkg>.sh` (macOS `brew`; Linux `pacman`/`yay`/`flatpak`/`asdf`/`app`) that installs it. For name-based managers the **filename minus `.sh` must equal the package leaf name** (drives the skip-check). For tapped brew casks, `brew tap` + `brew trust --tap` inside the script.
- **New system tweak:** create `<tier>/setup/tweak/<name>.sh`. Runs every bootstrap — make it idempotent.
- **New app config:** create `<app>/` under the relevant tier (`macos/` or `linux/`). **No `.gitignore` allowlisting needed** — the conventional deny-list tracks it automatically. It's symlinked into `~/.config/<app>` on the next `setup.sh`.
- **New zsh function/alias (macOS):** drop a `<name>.zsh` in `macos/zsh/rc.d/`. `.zshrc` sources all of them. The Linux/fish equivalent is a `<name>.fish` in `linux/fish/conf.d/`.

## Runtime-state hazard (important)

Because `~/.config/<app>` is a whole-dir symlink, anything an app **writes** into its config dir lands in the repo working tree. The most frequent offender: **zsh self-compiles `.zshrc` → `.zshrc.zwc` in `$ZDOTDIR` on every shell start**. Such runtime/generated paths MUST be kept out of git via the conventional `.gitignore` (already covers `**/zsh/*.zwc`, `**/zsh/.zsh_history`, `**/micro/backups/`, `**/micro/buffers/`, `**/fish/fish_variables`, etc.) and/or folded to a per-file symlink pointing at `~/.local/state/<app>/`. When adding a config dir whose app writes state in place, add the ignore rule.

## `.gitignore` (conventional deny-list)

`.gitignore` is a **conventional deny-list** (everything tracked by default; cruft/logs/runtime-state ignored) — **not** the old allowlist. New tracked dirs need no `!` entries. One special case is preserved: only `graphify-out/graph.json` is tracked (`graphify-out/*` ignored, `!graphify-out/graph.json`), since the rest of `graphify-out/` is machine-specific or regenerable.

## zsh layout (macOS)

`macos/setup/tweak/zsh.sh` writes `~/.zshenv` to set `ZDOTDIR=$HOME/.config/zsh` — and `~/.config/zsh` is now a symlink to `macos/zsh`, so the whole shell config still lives in this repo. `.zprofile` sets up Homebrew. `.zshrc` loads zinit, starship, autocomplete/autosuggestions/syntax-highlighting (the latter two `wait lucid`), zoxide as `cd`, then sources `rc.d/`.

## Multi-account git (`macos/zsh/rc.d/git-multi-account.zsh`, `linux/fish/conf.d/git-multi-account.fish`)

`git` is shadowed by a function that intercepts `clone`, `submodule add`, `submodule init`, `submodule update`. It parses the GitHub URL, resolves which of two accounts (`Adrian-LSY` for rooftop.my work, `AdrianLSY` for personal) has push access via `gh api`, runs the underlying git command with `GIT_SSH_COMMAND` pointing at the right key, then stamps that account's identity + SSH-signing config onto the resulting repo and every submodule. `ghs <account>` re-stamps the current repo. Keep the `command git ...` calls — bare `git` would recurse. The two account names appear in three case statements plus the resolution logic; update all together. There are **two parallel implementations** (zsh for macOS, fish for Linux) — keep them in sync.

## Other notable bits

- `ghp "msg"`: `git add . && git commit -m "msg" && git push` (sets upstream on first push).
- `ghu`: on the current repo + every submodule in parallel, fetches origin, fast-forwards (or hard-resets) the default branch, deletes branches whose upstreams are gone.
- `ai`: alias for `claude --settings '{"ultracode":true}' --dangerously-skip-permissions`. The `--settings '{"ultracode":true}'` turns on ultracode (xhigh effort + standing dynamic-workflow orchestration) at launch — the only way to activate it from the CLI (`--effort ultracode` collapses to plain `xhigh`; ultracode is session-scoped).
- `macos/aerospace/aerospace.toml` references `adrianlsy.github.io/AeroSpace` — a personal fork (`AdrianLSY/tap/aerospace-adrianlsy`), not upstream `nikitabobko/AeroSpace`. Hover-to-raise (`[auto-raise]`) is fork-specific.
- Secrets: a **gitleaks pre-commit hook** (`.pre-commit-config.yaml`, wired up by the brew module) scans staged changes and blocks commits containing secrets. Unlike the old allowlist, the conventional `.gitignore` no longer gates tracking by directory, so the gitleaks hook is the primary content-level defense — keep it installed (`pre-commit install`).

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
