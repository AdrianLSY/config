## REMOVED Requirements

### Requirement: The repository is the live config, consumed in place

**Reason**: The repo moves out of `~/.config` to an external path (canonically `~/.dotfiles`). `~/.config/<app>` is now a symlink into the repo, so a link layer between the app-read path and the tracked file is exactly the design — the removed requirement's assertion that there "MUST NOT be … a symlink layer" is now false.

**Migration**: Editing remains an edit of the repo, but through the symlink `~/.config/<app>` → `~/.dotfiles/<tier>/<app>` rather than because the repo *is* `~/.config`. Deployment behavior is now covered by the new "Deploy by per-app symlink from an external repo" requirement.

### Requirement: External-clone deploy by copy

**Reason**: The deploy mechanism reverses from destructive copy (`rm -rf ~/.config/<dir>` then `cp -r`) to per-app symlink. There is no longer a copy step to normalize directory names for.

**Migration**: `setup.sh` now symlinks each active-tier app dir into `~/.config` using backup-then-link (a pre-existing real target is moved to `<app>.bak.<timestamp>` first). The idempotency and non-destructiveness of this are specified in bootstrap-reliability; the symlink deploy itself is specified by the new "Deploy by per-app symlink from an external repo" requirement.

## ADDED Requirements

### Requirement: Deploy by per-app symlink from an external repo
The repository MUST live at an external path separate from `~/.config` (canonically `~/.dotfiles`), and MUST deploy each managed app directory as a symlink `~/.config/<app>` → `<repo>/<tier>/<app>`, where `<tier>` is the OS tier (`macos` or `linux`) selected at bootstrap. Editing a file through the symlink MUST be a repo edit — there MUST be no copy, sync, or template step between the tracked file and the file the app reads. `~/.config` MUST NOT be a git working tree. Within a tier, the reserved `setup/` directory (and repo-meta) MUST NOT be symlinked into `~/.config`; only app config directories are deployed.

#### Scenario: Editing a config through the symlink
- **WHEN** a tracked file under `<repo>/<tier>/<app>/` is edited (whether reached via `~/.config/<app>/` or directly)
- **THEN** the app reads the change directly through the symlink, and the edit is a repo change with no sync or link-rebuild step

#### Scenario: Deploying an app directory
- **WHEN** `setup.sh` deploys a managed app directory for the active tier
- **THEN** `~/.config/<app>` afterward is a symlink pointing at `<repo>/<tier>/<app>`

#### Scenario: Reserved setup dir is not deployed
- **WHEN** `setup.sh` iterates the active tier's directories to deploy
- **THEN** the tier's `setup/` directory is skipped and no `~/.config/setup` symlink is created

## MODIFIED Requirements

### Requirement: Secrets are excluded by the allowlist, not sourced
Because the repository is now external and holds only the two OS tiers, the shared `lib/`, and repo meta, secret-bearing files that live under `~/.config` (e.g. `gh/hosts.yml`, `raycast/`, `cagent/user-uuid`) are simply not in the repo when their directory is not symlinked — no allowlist `.gitignore` is required to hide them. For directories that ARE symlinked into `~/.config`, any secret-bearing or runtime file that the app writes into that dir MUST be gitignored within the repo (or folded to a per-file symlink outside the tree) so it is not tracked. Tracked config files MUST contain no secrets, and there MUST be no `*.local` sourcing convention.

#### Scenario: A secret-bearing file under an unmanaged ~/.config dir
- **WHEN** the repository is inspected for tracked files
- **THEN** files like `gh/hosts.yml` are absent from the repo entirely, because their `~/.config` dir is not symlinked and thus not part of the external repo

#### Scenario: A secret-bearing file inside a symlinked dir
- **WHEN** an app writes a secret-bearing file into a symlinked app dir (e.g. a token cached under a linked config dir)
- **THEN** that path is matched by the repo's conventional `.gitignore` (or folded outside the tree) and is not tracked, even though the surrounding directory is symlinked from the repo
