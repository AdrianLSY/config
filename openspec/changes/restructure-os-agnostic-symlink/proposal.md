## Why

Today the git repository *is* `~/.config`: `.git` lives at `~/.config/.git`, every managed app directory maps 1:1 to `~/.config/<app>`, and `setup.sh` deploys by `rm -rf ~/.config/<dir> && cp -r <dir>`. Three problems fall out of this coupling:

- **Allowlist-`.gitignore` tax.** Because the repo shares its root with dozens of unmanaged app dirs (`gh`, `uv`, `raycast`, `configstore`, `cagent`, `tiger`, `git`, `openspec`, `projects`, `fish`, …), the `.gitignore` must default-ignore `*` and re-`!`-allowlist every managed path. Every new tracked directory needs two hand-added lines or it silently vanishes.
- **Branch-per-OS divergence.** macOS lives on `main`, Linux on `cachyos-home`; they have diverged by ~276 files and are explicitly flagged "never merge wholesale." OS selection is a branch checkout, not a runtime decision, and the two histories can never safely reconcile.
- **Destructive copy deploy.** `rm -rf` then `cp -r` means edit-live ≠ edit-repo unless you remember to re-run bootstrap, and a partial state is briefly destructive.

Moving the repo **out** of `~/.config` to a standalone `~/.dotfiles`, splitting content into `macos/` and `linux/` tiers, and deploying each app dir as a **backup-then-link** symlink resolves all three: the allowlist gymnastics disappear (the repo only holds what we put there), OS selection becomes a `uname` dispatch at bootstrap time, and editing through a symlink is still editing the repo.

## What Changes

- **BREAKING:** The repository moves from `~/.config` (repo == config) to an external path, canonically `~/.dotfiles`. `.git` relocates from `~/.config/.git` to `~/.dotfiles/.git`; `~/.config` stops being a git working tree.
- **BREAKING:** Deploy mechanism reverses from destructive **copy** (`rm -rf && cp -r`) to per-app **symlink** (`~/.config/<app>` → `~/.dotfiles/<tier>/<app>`). Editing through the symlink is a repo edit with no sync step.
- **BREAKING:** `.gitignore` changes from allowlist-style (`*` then `!` exceptions) to a conventional deny-list; the repo root now contains only tier dirs plus shared `lib/` and repo meta.
- **BREAKING:** Content is reorganized into two OS tiers — `macos/` and `linux/` — each holding its own app dirs **and** its own `setup/` (macOS: `brew`, `tweak`; Linux: `yay`, `tweak`). No `common/`/`shared/` config tier; `micro/` (byte-identical across OSes) is duplicated verbatim into both tiers, and `zed/` is mostly-shared but divergent (its `settings.json` differs by ~126 lines) so it is duplicated with a per-tier `settings.json`.
- **BREAKING:** Branch model collapses: `main` (macOS) and `cachyos-home` (Linux) are unified onto one branch by moving each OS's files into its own tier — a structured move, not a wholesale merge. OS is chosen at runtime via `uname -s`.
- `setup.sh` gains an OS-dispatch front end: `uname -s` → pick `macos`/`linux` tier → symlink that tier's app dirs into `~/.config` (backup-then-link) → run the tier's `setup/.setup.sh`.
- New conflict policy: **backup-then-link** — a pre-existing real `~/.config/<app>` (or wrong symlink) is moved to `<app>.bak.<timestamp>` before the symlink is created; an already-correct symlink is a no-op; nothing is overwritten without a backup. Unmanaged `~/.config` dirs are never touched.
- New **runtime-state rule:** because whole-dir symlinks route app-written state (e.g. `zsh/.zsh_history`, the self-compiled `zsh/.zshrc.zwc`, `micro/backups`, `micro/buffers`, `fish/fish_history`) through the link into the repo tree, such runtime/generated paths MUST be gitignored within the repo (and/or symlinked per-file, Stow-style folding, to a state dir outside the tree).
- Linux software provisioning added via an AUR helper (`yay`), mirroring the brew model (one script per package, per-package failure isolation, logs, skip-check).
- Symlink helper is a small hand-rolled lib at repo root (`lib/link.sh`), Stow-inspired; it is shared bootstrap *code* used by both tiers, not a config tier.

## Capabilities

### New Capabilities
None. Every change maps onto the five existing capabilities as spec deltas.

### Modified Capabilities
- **config-deployment** — repo is no longer the live config in place; deploy is external-repo per-app symlink (backup-then-link) instead of copy; secrets are excluded by simply not being in the external repo (allowlist gone), with runtime/secret files gitignored inside symlinked dirs.
- **config-tracking** — runtime/generated state must still not be tracked, but now because whole-dir symlinks route app-written state into the repo tree; allowlist-tracking abandoned for a conventional `.gitignore` over tier-plus-`lib` content.
- **bootstrap-orchestration** — `setup.sh` dispatches by `uname -s` to a tier, each tier has its own `setup/` with its own `ORDER`; clone-from-anywhere preserved but the in-place skip-copy branch is replaced by symlink deploy regardless of CWD.
- **software-provisioning** — Homebrew bootstrap scoped to the macOS tier; Linux tier provisions via `yay`; one-script-per-package generalized to the active tier's package manager; non-official-tap trust scoped to brew.
- **bootstrap-reliability** — truthful exit still holds but "still copies on partial failure" becomes "still symlinks"; skip-check generalized per-OS package manager; permission pass must not touch unmanaged `~/.config`; new requirement that symlink deploy is idempotent and non-destructive; ordering-safe tweaks reflect symlink-deploy timing.

## Impact

- **Affected specs:** config-deployment, config-tracking, bootstrap-orchestration, software-provisioning, bootstrap-reliability.
- **Affected code (apply phase, out of scope here):** `setup.sh`, `setup/.setup.sh` and its module runners (relocated under each tier as `<tier>/setup/`), a new shared `lib/link.sh`, `.gitignore`, the repo directory layout, and the git remote/working-tree location. The canonical tracked repo root becomes: `macos/`, `linux/`, `lib/`, `setup.sh`, `README.md`, `CLAUDE.md`, `.gitignore`.
- **Documentation:** `CLAUDE.md` and `README.md` carry load-bearing descriptions of the copy model, the allowlist `.gitignore`, the `ORDER=(brew tweak)` cascade, the branch-per-OS model, and the graphify "repo == `~/.config`" rule — all of which this change invalidates and which must be rewritten.
- **Assumptions to audit:** anything relying on "repo == `~/.config`" — graphify auto-update hooks, `git-multi-account.zsh` (per-repo identity stamping), the `ai` alias — must keep working with the repo at `~/.dotfiles` and configs as symlinks.
- **Migration:** fresh machines clone to `~/.dotfiles` and run `setup.sh`; the existing mac commits/pushes its live state, has the structured move applied so `~/.dotfiles` carries its latest history, then retires `~/.config/.git` **before** running `setup.sh` to relink each managed `~/.config/<app>` via backup-then-link. Rollback is trivial: remove the symlink, restore the `.bak.<ts>`.
