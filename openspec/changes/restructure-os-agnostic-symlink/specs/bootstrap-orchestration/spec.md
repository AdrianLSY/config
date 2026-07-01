## MODIFIED Requirements

### Requirement: Cascading module-runner structure
`setup.sh` MUST first detect the operating system via `uname -s` and select the corresponding OS tier (`macos` or `linux`), then delegate to that tier's `setup/.setup.sh`, which runs bootstrap sub-modules in the order declared by its own `ORDER` array (macOS: `brew` then `tweak`; Linux: `pacman`, `yay`, `flatpak`, `app`, `asdf`, then `tweak`). Each sub-module is a directory containing its own `.setup.sh` runner that iterates its sibling `*.sh` scripts. Adding a unit of work MUST be possible by dropping a single `*.sh` file into the relevant module directory within a tier without editing the runners.

#### Scenario: OS dispatch selects the tier
- **WHEN** `setup.sh` runs on a machine where `uname -s` reports Darwin
- **THEN** the `macos` tier is selected and its `setup/.setup.sh` is delegated to (and on Linux the `linux` tier is selected instead)

#### Scenario: Module order within a tier
- **WHEN** the bootstrap runs the macOS tier
- **THEN** the `brew` sub-module completes before the `tweak` sub-module, per that tier's `ORDER` array

#### Scenario: Adding a unit of work
- **WHEN** a new `<tier>/setup/<module>/<name>.sh` file is added
- **THEN** the corresponding tier runner picks it up on the next run with no edit to the runner itself

### Requirement: Per-script logging via tee and PIPESTATUS
Each module runner MUST capture a script's combined stdout+stderr to a `<script>.log` via `tee`, read that script's real exit status from `${PIPESTATUS[0]}` (never `tee`'s always-zero status), delete the log on success, retain it on failure, and print an aggregate ✅/❌ summary. The mechanics are unchanged from the baseline, but the runners and their `<script>.log` files now live per-tier under `<tier>/setup/<module>/`. (The truthful top-level exit code is guaranteed separately by the bootstrap-reliability baseline.)

#### Scenario: A unit fails
- **WHEN** a `*.sh` unit under `<tier>/setup/<module>/` exits non-zero
- **THEN** its `<script>.log` in that tier's module directory is retained and it appears in the ❌ Failed: summary

#### Scenario: A unit succeeds
- **WHEN** a `*.sh` unit under `<tier>/setup/<module>/` exits zero
- **THEN** its log is deleted and it appears in the ✅ summary

### Requirement: Clone-from-anywhere entrypoint
The repository MUST be bootstrappable by cloning it to any location (canonically `~/.dotfiles`) and running `./setup.sh`. Regardless of the current working directory, `setup.sh` MUST detect the OS, select the tier, and symlink that tier's app directories into `~/.config` using backup-then-link. There is no in-place/skip-copy branch — the repo is never `~/.config`, so deployment is always by symlink.

#### Scenario: Bootstrapped from an external clone
- **WHEN** `./setup.sh` runs from `~/.dotfiles` (or any other directory)
- **THEN** the active tier's config directories are symlinked into `~/.config` (backup-then-link) and the tier's modules run

#### Scenario: No in-place shortcut
- **WHEN** `./setup.sh` runs from any directory
- **THEN** it always symlinks the active tier into `~/.config`; there is no branch that treats the current directory as the live `~/.config`
