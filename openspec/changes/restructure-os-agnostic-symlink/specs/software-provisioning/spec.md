## MODIFIED Requirements

### Requirement: Homebrew bootstrap into the current shell
Within the macOS tier, the `brew` module MUST install Homebrew via the official installer when `command -v brew` fails, and MUST `eval "$(/opt/homebrew/bin/brew shellenv)"` in the running shell immediately after, so subsequent `brew` calls in the same bootstrap succeed. The Apple Silicon prefix `/opt/homebrew` is used. This requirement applies only on Darwin; the Linux tier provisions via its own AUR-helper module instead.

#### Scenario: Homebrew missing on macOS
- **WHEN** `command -v brew` fails at the start of the macOS `brew` module
- **THEN** Homebrew is installed and its shellenv is evaluated into the current shell

#### Scenario: Homebrew present
- **WHEN** `brew` is already available
- **THEN** the install step is skipped

### Requirement: One install script per package
Software MUST be expressed as one `<tier>/setup/<pkgmgr>/<pkg>.sh` script per package, invoking the active tier's package manager (macOS: `brew install` / `brew install --cask`; Linux: the AUR helper `yay`), not a single declarative manifest. This model provides per-package failure isolation and per-package logs: a single failing package MUST NOT abort the rest of the run. (The idempotent skip-check that prevents reinstalling an already-present package is specified by the bootstrap-reliability baseline.)

#### Scenario: One package fails
- **WHEN** one `<tier>/setup/<pkgmgr>/<pkg>.sh` exits non-zero
- **THEN** the remaining package scripts still run and the failure is reported in the summary

#### Scenario: Package manager matches the tier
- **WHEN** a package script runs in the Linux tier
- **THEN** it installs via `yay`, whereas the equivalent macOS-tier script installs via `brew`

### Requirement: Trust non-official taps in-script
Within the macOS/`brew` module, a package installed from a non-official tap MUST `brew tap` and `brew trust --tap` that tap inside its own install script, because current Homebrew refuses to load casks from untrusted taps — which would break both the install and the name-based skip-check on a fresh machine. This requirement is scoped to the brew module; the Linux `yay` module has its own AUR-repository handling.

#### Scenario: Cask from a non-official tap
- **WHEN** a package such as `aerospace-adrianlsy` or `tiger-cli` installs from a non-official tap in the macOS tier
- **THEN** its script taps and trusts that tap before `brew install`, so the cask resolves by name on a fresh machine

## ADDED Requirements

### Requirement: Linux provisioning via an AUR helper
The Linux tier MUST provision software through an AUR helper (`yay`). The `yay` module MUST ensure `yay` (and its backing `pacman`) are present, then iterate one install script per package under `linux/setup/yay/`, with per-package failure isolation and per-package logs mirroring the macOS `brew` model. A single failing package MUST NOT abort the rest of the run.

#### Scenario: yay missing on Linux
- **WHEN** the Linux tier's `yay` module runs on a machine without `yay`
- **THEN** the module ensures `yay`/`pacman` are available before iterating package scripts

#### Scenario: One Linux package fails
- **WHEN** one `linux/setup/yay/<pkg>.sh` exits non-zero
- **THEN** the remaining package scripts still run, the failing one retains its log, and the failure is reported in the summary
