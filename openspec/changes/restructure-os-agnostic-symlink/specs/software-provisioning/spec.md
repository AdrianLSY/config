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
Software MUST be expressed as one `<tier>/setup/<module>/<pkg>.sh` script per package, invoking that module's provisioning mechanism (macOS: `brew install` / `brew install --cask`; Linux: the tier's native mechanisms — `pacman`, the AUR helper `yay`, `flatpak`, `asdf` plugins, and script-based `app` installers), not a single declarative manifest. This model provides per-package failure isolation and per-package logs: a single failing package MUST NOT abort the rest of the run. (The idempotent skip-check that prevents reinstalling an already-present package is specified by the bootstrap-reliability baseline.)

#### Scenario: One package fails
- **WHEN** one `<tier>/setup/<module>/<pkg>.sh` exits non-zero
- **THEN** the remaining package scripts still run and the failure is reported in the summary

#### Scenario: Mechanism matches the module
- **WHEN** a package script runs in the Linux tier's `pacman` or `yay` module
- **THEN** it installs via that module's mechanism (e.g. `pacman`/`yay`), whereas the equivalent macOS-tier script installs via `brew`

### Requirement: Trust non-official taps in-script
Within the macOS/`brew` module, a package installed from a non-official tap MUST `brew tap` and `brew trust --tap` that tap inside its own install script, because current Homebrew refuses to load casks from untrusted taps — which would break both the install and the name-based skip-check on a fresh machine. This requirement is scoped to the brew module; the Linux `yay` module has its own AUR-repository handling.

#### Scenario: Cask from a non-official tap
- **WHEN** a package such as `aerospace-adrianlsy` or `tiger-cli` installs from a non-official tap in the macOS tier
- **THEN** its script taps and trusts that tap before `brew install`, so the cask resolves by name on a fresh machine

## ADDED Requirements

### Requirement: Linux provisioning via a multi-module package cascade
The Linux tier MUST provision software through a multi-module cascade run in the order declared by `linux/setup/.setup.sh`'s `ORDER` array — `pacman`, `yay`, `flatpak`, `app`, `asdf`, `tweak` — where `pacman` installs official-repo packages (and bootstraps the AUR helper), `yay` installs AUR packages, `flatpak` installs Flatpak applications, `app` runs script-based installers for tools without a repo package, `asdf` installs language runtimes via asdf plugins, and `tweak` applies system tweaks. Every provisioning module MUST follow the one-script-per-package model with per-package failure isolation and per-package logs; a single failing package MUST NOT abort the rest of the run. The AUR helper `yay` MUST be ensured present (bootstrapped via `pacman`) before the `yay` module iterates its packages.

#### Scenario: AUR helper bootstrapped before use
- **WHEN** the Linux tier runs on a machine without `yay`
- **THEN** the `pacman` module (running before `yay` in the `ORDER`) installs `yay` so the `yay` module can iterate its AUR packages

#### Scenario: One Linux package fails
- **WHEN** one `linux/setup/<module>/<pkg>.sh` exits non-zero
- **THEN** the remaining package scripts still run, the failing one retains its log, and the failure is reported in the summary

#### Scenario: Module order preserved
- **WHEN** the Linux tier cascade runs
- **THEN** the modules execute in the `pacman → yay → flatpak → app → asdf → tweak` order declared by `linux/setup/.setup.sh`
