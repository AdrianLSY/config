# config

My personal `~/.config` — live app configs plus a `setup.sh` bootstrap that
provisions a fresh machine (Homebrew packages + system tweaks) and deploys these
dotfiles.

## Layout

- `zsh/`, `zed/`, `ghostty/`, `aerospace/`, `vivaldi/`, `micro/`, `linearmouse/` —
  live config for each app, consumed in place from `~/.config/<app>/`.
- `bin/` — helper scripts on `PATH`.
- `setup/` — the bootstrap installer: `brew/` (package installs) and `tweak/`
  (idempotent system tweaks).

## Bootstrap

The repo is meant to be cloned anywhere and bootstrapped from there; the real
install lives in `~/.config`.

```sh
git clone https://github.com/AdrianLSY/config.git ~/config-src   # or anywhere
cd ~/config-src
./setup.sh
```

`setup.sh`:

1. **Refuses to run as root** — never `sudo ./setup.sh`.
2. On macOS, **ensures Command Line Tools** (git + clang, which Homebrew needs)
   are installed, triggering the installer and waiting if they're missing.
3. Runs `setup/.setup.sh`, which runs each module in order: `brew` (installs
   Homebrew if missing, then every `setup/brew/*.sh`) then `tweak` (every
   `setup/tweak/*.sh`).
4. If invoked from **outside** `~/.config`, copies every app directory + the meta
   files into `~/.config` by destructive replace (`rm -rf ~/.config/<dir> &&
   cp -r`). Run **in place** from `~/.config` and the copy step is skipped — you
   edit the live config directly, no symlinks.

### Prerequisite

**macOS Command Line Tools.** `setup.sh` installs them for you; if the automated
install stalls, run `xcode-select --install`, then re-run `./setup.sh`. Homebrew
and every package are installed by the bootstrap.

## Adding things

- **Brew package:** create `setup/brew/<pkg>.sh` containing `brew install <pkg>`
  (or `--cask`). **The filename minus `.sh` must equal the formula/cask name** —
  it drives the already-installed skip-check.
- **System tweak:** create `setup/tweak/<name>.sh`. It runs on every bootstrap,
  so make it idempotent.
- **New app config:** create `<app>/` at the repo root, then allowlist it in
  `.gitignore` with `!<app>/` and `!<app>/**` (see below).

## Secrets & the allowlist

`.gitignore` is **allowlist-style**: it ignores everything (`*`), then re-includes
known-safe paths with `!` exceptions. This is the primary defense against
committing a secret — anything under `~/.config` is untracked unless explicitly
allowlisted, so tracking a new directory requires adding both `!<dir>/` and
`!<dir>/**`.

As a second layer, a **gitleaks pre-commit hook** (`.pre-commit-config.yaml`)
scans every staged change and blocks the commit if it finds a secret — including
secrets inside allowlisted directories, where the allowlist offers no
content-level protection. It's wired up on bootstrap by `setup/brew/gitleaks.sh`,
`setup/brew/pre-commit.sh`, and `setup/tweak/pre-commit.sh` (which runs
`pre-commit install`).

## Branches

Branches map to machines: `macos`, `cachyos-home`, `cachyos-work`. `main` is the
shared base. Per-machine changes stay on the machine branch; only truly
cross-platform changes go to `main`.
