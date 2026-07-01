# config

My personal dotfiles for **macOS and Linux**, plus a `setup.sh` bootstrap that
provisions a fresh machine (packages + system tweaks) and deploys these configs.

The repo lives at an **external** path (e.g. `~/.dotfiles`), **not** at
`~/.config`. It deploys config *into* `~/.config` by per-app **symlink**
(`~/.config/<app>` → `~/.dotfiles/<tier>/<app>`), so editing through the symlink
is still editing the repo.

## Layout

Content is split into two OS **tiers**; the OS is chosen at runtime via `uname`:

- `macos/` — the macOS machine: `zsh/`, `zed/`, `ghostty/`, `aerospace/`,
  `linearmouse/`, `vivaldi/`, `bin/`, `micro/`, `starship.toml`, and its own
  `setup/` (`brew`, `tweak`).
- `linux/` — the Linux (Arch/CachyOS) machine: `fish/`, `hypr/`, `waybar/`,
  `kitty/`, `mako/`, `rofi/`, `swaylock/`, `nvim/`, `btop/`, `tmux/`, `gtk-*`,
  `qt5ct/`, `qt6ct/`, `zed/`, `micro/`, `mimeapps.list`, and its own `setup/`
  (`pacman`, `yay`, `flatpak`, `app`, `asdf`, `tweak`).
- `lib/link.sh` — the shared symlink helper (bootstrap code, not config).
- Repo meta at the root (`setup.sh`, `README.md`, `CLAUDE.md`, `.gitignore`, …)
  is never symlinked into `~/.config`.

There is no `common/` tier: genuinely-shared config (`micro/`, and `zed/` with a
per-tier `settings.json`) is duplicated into both tiers by design.

## Bootstrap

Clone anywhere and run `setup.sh` — there is no in-place mode; it always deploys
by symlink.

```sh
git clone https://github.com/AdrianLSY/config.git ~/.dotfiles
~/.dotfiles/setup.sh
```

`setup.sh`:

1. **Refuses to run as root** — never `sudo ./setup.sh`.
2. **Detects the OS** via `uname -s` and selects the `macos` or `linux` tier
   (errors on anything else).
3. Runs a **repo-scoped** `chmod` (never touches `~/.config` or `.git`).
4. On macOS, **ensures Command Line Tools** (git + clang, which Homebrew needs).
5. **Symlinks the tier's app dirs into `~/.config`** via backup-then-link (see
   below), skipping the reserved `setup/` dir.
6. Runs the tier's `setup/.setup.sh` cascade (macOS: `brew` → `tweak`; Linux:
   `pacman` → `yay` → `flatpak` → `app` → `asdf` → `tweak`), then exits with the
   cascade's true status.

### Backup-then-link (safe on a machine with an existing `~/.config`)

For each app dir/file in the tier, `setup.sh`:

- **leaves it alone** if `~/.config/<app>` is already the correct symlink (no-op);
- **backs it up** to `<app>.bak.<timestamp>` if a real dir/file or a different
  symlink is in the way, then creates the symlink;
- **creates the symlink** if nothing is there.

Nothing is ever overwritten without a timestamped backup, and **unmanaged
`~/.config` entries** (`gh/`, `uv/`, `raycast/`, …) are never touched. Re-running
is idempotent. To roll back an app: remove its symlink and restore the `.bak.<ts>`.

### Prerequisite

**macOS Command Line Tools** — `setup.sh` installs them for you; if the automated
install stalls, run `xcode-select --install` and re-run. On Linux, a working
`pacman` (CachyOS/Arch base) is assumed; the bootstrap installs `yay` and the rest.

## Adding things

- **Package:** create `<tier>/setup/<pkgmgr>/<pkg>.sh` (macOS `brew`; Linux
  `pacman`/`yay`/`flatpak`/`asdf`/`app`). For name-based managers **the filename
  minus `.sh` must equal the package's leaf name** — it drives the skip-check.
- **System tweak:** create `<tier>/setup/tweak/<name>.sh`. Runs every bootstrap,
  so make it idempotent.
- **New app config:** create `<app>/` under the relevant tier. No `.gitignore`
  edits needed — the conventional deny-list tracks it automatically.

## Runtime state & secrets

Because config dirs are whole-dir symlinks, anything an app **writes** into its
config dir (e.g. zsh's self-compiled `.zshrc.zwc`, `.zsh_history`, micro's
`backups/`) lands in the repo tree — so those runtime/generated paths are
gitignored. `.gitignore` is a conventional deny-list (everything tracked by
default; cruft, logs, and runtime state ignored).

A **gitleaks pre-commit hook** (`.pre-commit-config.yaml`, installed by the
bootstrap) scans every staged change and blocks commits containing secrets.

## Branches

A **single branch** carries both machines; the OS is selected at runtime by
`setup.sh`. (This replaced the old branch-per-machine model.)
