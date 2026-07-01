## REMOVED Requirements

### Requirement: Tracked config directories are explicitly allowlisted

**Reason**: The allowlist-style `.gitignore` (`*` then `!` exceptions) existed only because the repo shared its root with unmanaged `~/.config` dirs. With the external repo holding only the two OS tiers, the shared `lib/`, and meta, a conventional deny-list `.gitignore` suffices and per-directory `!<dir>/` + `!<dir>/**` allowlisting is abandoned.

**Migration**: Replace the allowlist `.gitignore` with a conventional ignore list. Tracked config directories no longer need explicit `!` entries; they are tracked by virtue of living under a tier dir in an external repo.

## ADDED Requirements

### Requirement: Repo contains only managed tiers under a conventional .gitignore
The external repository's tracked content MUST consist primarily of the OS tier directories (`macos/` and `linux/`, each including its own `setup/` bootstrap tooling), the shared `lib/` bootstrap code, and repo-meta files (`setup.sh`, `README.md`, `CLAUDE.md`, `.gitignore`) — and no unmanaged app config. The `.gitignore` MUST be a conventional deny-list (ignore specific runtime/generated/secret paths) rather than an allowlist (`*` then `!` exceptions). A single intra-repo tier-to-tier symlink (e.g. `linux/micro` → `../macos/micro`) is the sanctioned de-duplication escape hatch and MAY exist within the tracked tree; a `common/` config tier MUST NOT be introduced.

#### Scenario: Adding a new managed config directory
- **WHEN** a new app directory is added under a tier (e.g. `macos/<app>/`)
- **THEN** it is tracked without needing any `!<dir>/` allowlist entry in `.gitignore`

#### Scenario: Gitignore is a deny-list
- **WHEN** `.gitignore` is inspected
- **THEN** it does not begin by ignoring `*` and re-including managed paths; it names specific paths to ignore instead

#### Scenario: Intra-repo escape-hatch symlink is permitted
- **WHEN** a tier-to-tier symlink such as `linux/micro` → `../macos/micro` is used to avoid duplicating identical config
- **THEN** it is a valid tracked entry and does not require introducing a `common/` config tier

## MODIFIED Requirements

### Requirement: Runtime and generated state is not tracked
The repository MUST NOT track per-machine runtime or generated state. Shell history, compiled zsh artifacts, session/backup/buffer files, generated completions, and compiler caches SHALL be kept out of git. Under the new whole-directory symlink deploy, an app writes state into its config dir *through* the symlink and thus INTO the repo working tree, so these runtime/generated paths MUST be kept out of git either by (a) matching them in the repo's `.gitignore`, and/or (b) symlinking those particular subpaths per-file (Stow-style folding) so the volatile file resolves to a non-tracked location outside the tree (canonically `~/.local/state/<app>/`, or `~/.cache/<app>/` for pure caches). The enumeration MUST at minimum cover `zsh/.zsh_history`, `zsh/*.zwc` — explicitly the self-compiled `zsh/.zshrc.zwc` that zsh regenerates on every shell start when `.zshrc` is newer than the `.zwc` — `micro/backups/`, `micro/buffers/`, `fish/fish_history`, and generated `fish/completions/`.

#### Scenario: Shell history
- **WHEN** the repository is inspected for tracked files
- **THEN** `zsh/.zsh_history` (and the equivalent `fish/fish_history`) is not tracked and is matched by `.gitignore` or is folded to a non-tracked location

#### Scenario: zsh self-zcompile artifact
- **WHEN** a shell starts and zsh regenerates `.zshrc.zwc` in the symlinked `zsh/` dir, writing it through the symlink into the repo working tree
- **THEN** `zsh/.zshrc.zwc` (matched by `zsh/*.zwc`) is not tracked and `git status` does not show it as untracked or modified

#### Scenario: App writes state through the symlink
- **WHEN** an app writes runtime state (history, caches, backups, buffers, compiled artifacts) into a symlinked config dir, so the write lands inside the repo working tree
- **THEN** that path is either matched by the repo's `.gitignore` or is a per-file symlink to a non-tracked location, so `git status` does not show it as an untracked or modified tracked file
