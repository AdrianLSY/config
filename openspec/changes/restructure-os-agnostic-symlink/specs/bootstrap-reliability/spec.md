## MODIFIED Requirements

### Requirement: Truthful exit-code propagation
The top-level `setup.sh` SHALL report the true outcome of the active tier's `setup/.setup.sh` and exit with a non-zero status when any module fails. It MUST capture the module runner's status through the `tee` pipe via `${PIPESTATUS[0]}` (matching the inner runners) rather than relying on `tee`'s exit code. Symlink deployment of the active tier's configs into `~/.config` SHALL still occur on partial failure so a flaky package never blocks dotfile installation, but the final exit status MUST reflect the failure.

#### Scenario: A module fails
- **WHEN** the active tier's `setup/.setup.sh` exits non-zero (e.g. a package failed)
- **THEN** `setup.sh` prints a failure indication, still symlinks the tier's configs into `~/.config`, and exits with a non-zero status

#### Scenario: All modules succeed
- **WHEN** the active tier's `setup/.setup.sh` exits zero
- **THEN** `setup.sh` reports success and exits zero

### Requirement: Idempotent brew skip-check for tapped casks
Every install script's filename (minus `.sh`) SHALL equal the leaf name under which the active tier's package manager lists the installed package, so the per-OS skip-check matches an already-installed package and does not reinstall it on subsequent runs. On macOS the check is `brew list "$PKG" || brew list --cask "$PKG"`; on Linux it is `yay -Q "$PKG"` (equivalently `pacman -Q "$PKG"`). The filename-equals-package-leaf-name rule persists within each tier.

#### Scenario: aerospace cask already installed (macOS)
- **WHEN** the bootstrap runs again on a machine where the `aerospace-adrianlsy` cask is installed
- **THEN** the `brew` skip-check recognizes it as installed and does not re-run the install

#### Scenario: Linux package already installed
- **WHEN** the bootstrap runs again on a Linux machine where a `yay` package is already installed
- **THEN** the `yay -Q` skip-check recognizes it as installed and does not re-run the install

### Requirement: Repo-scoped permission changes
The bootstrap's chmod passes SHALL be limited to paths the repository manages under the external repo (canonically `~/.dotfiles`). They MUST NOT recursively chmod unrelated files under `~/.config`, and MUST exclude the `.git` directory. Additionally, the symlink deployment MUST NOT chmod, delete, or overwrite unmanaged `~/.config` entries — it operates only on the active tier's managed app directories.

#### Scenario: Unrelated config present in ~/.config
- **WHEN** `~/.config` contains another application's files not managed by this repo (e.g. `gh`, `uv`, `raycast`)
- **THEN** the bootstrap leaves those files' permissions unchanged and does not move or delete them

#### Scenario: Git internals
- **WHEN** the permission pass runs
- **THEN** files under `.git/` are not chmodded

### Requirement: Ordering-safe tweaks
Tweak scripts that run relative to the symlink deploy MUST NOT fail because a `~/.config` target does not yet exist. Because symlink deployment and tweaks may run in either order within a tier, a tweak SHALL either operate on the in-tree source under `<repo>/<tier>/` or first ensure its `~/.config` target (or its parent) exists before acting.

#### Scenario: Fresh bootstrap before symlinks exist
- **WHEN** the bootstrap runs on a machine where the `~/.config` symlink for a tweak's target does not yet exist
- **THEN** the tweak completes without error by operating on the in-tree source or ensuring its target first, and the resulting shell configuration still loads correctly

## ADDED Requirements

### Requirement: Symlink deployment is idempotent and non-destructive
Symlink deployment MUST be idempotent and non-destructive. Relinking a `~/.config/<app>` that is already the correct symlink into `<repo>/<tier>/<app>` SHALL be a no-op. If `~/.config/<app>` already exists as a real file/directory or as a wrong symlink, it MUST be moved aside to `<app>.bak.<timestamp>` before the correct symlink is created. Nothing SHALL be overwritten without first creating such a backup. The deploy loop MUST enumerate only the active tier's app directories; unmanaged `~/.config` entries MUST NOT be enumerated, moved, backed up, symlinked, or altered in any way.

#### Scenario: Relinking an already-correct symlink
- **WHEN** deploy runs and `~/.config/<app>` is already the correct symlink into the active tier
- **THEN** nothing is changed and no backup is created

#### Scenario: Pre-existing real target is backed up
- **WHEN** deploy runs and `~/.config/<app>` exists as a real directory (or a wrong symlink)
- **THEN** it is moved to `<app>.bak.<timestamp>` and then replaced by the correct symlink, with no data overwritten in place

#### Scenario: Unmanaged entries are never touched
- **WHEN** `~/.config` contains unmanaged dirs (e.g. `gh`, `uv`, `raycast`) alongside managed ones
- **THEN** the deploy loop enumerates only the active tier's app dirs and leaves every unmanaged entry entirely untouched — not moved, backed up, symlinked, or chmodded

#### Scenario: Re-running deploy is stable
- **WHEN** deploy runs a second time on an already-linked tier
- **THEN** every managed app is a no-op and no new `.bak.<timestamp>` backups are created
