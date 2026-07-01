## 1. Repo relocation and layout

- [x] 1.1 Create the external repo root (canonically `~/.dotfiles`) and plan the move of `.git` from `~/.config/.git` to `~/.dotfiles/.git` so `~/.config` ceases to be a working tree.
- [x] 1.2 Establish the canonical tracked repo root inventory: `macos/`, `linux/`, `lib/`, `setup.sh`, `README.md`, `CLAUDE.md`, `.gitignore` — used verbatim by tasks 6.1 and the config-tracking spec.
- [x] 1.3 Define the two tier dirs `macos/` and `linux/`; within each, app config dirs (symlinked) and the reserved `setup/` (never symlinked).
- [x] 1.4 Plan the structured move: `git mv` `main`'s app dirs into `macos/`, `cachyos-home`'s app dirs into `linux/` (each OS's files into its own tier — NOT a wholesale merge), collapsing the two branches into one.
- [x] 1.5 Place each OS's bootstrap tooling under its own tier as `macos/setup/{brew,tweak}` and `linux/setup/{pacman,yay,flatpak,app,asdf,tweak}` (Option A layout; the Linux cascade is adopted wholesale from `cachyos-home`).
- [x] 1.6 Record the reserved-name rule: within a tier, `setup/` is bootstrap tooling and is never symlinked into `~/.config`.
- [x] 1.7 Duplicate genuinely-shared config into both tiers: `micro/` verbatim (byte-identical) into `macos/micro` and `linux/micro`; `zed/` into both with a per-tier `settings.json` (near-identical, ~126-line divergence). Record the single intra-repo tier-to-tier symlink escape hatch (e.g. `linux/micro` → `../macos/micro`) as available but not adopted; do NOT introduce a `common/` config tier.
- [x] 1.8 Confirm `lib/` sits at repo root as shared bootstrap code (not a config tier) and is invoked by both tiers' `setup.sh`.

## 2. Symlink deploy library (design-level)

- [x] 2.1 Specify `lib/link.sh` behavior: given a tier app dir, compute target `~/.config/<app>` and apply backup-then-link.
- [x] 2.2 Specify the three cases: correct symlink → no-op; real dir/file or wrong symlink → `mv` to `<app>.bak.<timestamp>` then symlink; missing → symlink.
- [x] 2.3 Specify the non-destructive guarantees: never overwrite without backup; enumerate ONLY the active tier's app dirs; never touch, chmod, or delete unmanaged `~/.config` entries.
- [x] 2.4 Confirm idempotency: re-running deploy over an already-linked tier makes no changes and creates no new `.bak.<ts>` backups.

## 3. Bootstrap orchestration changes

- [x] 3.1 Add OS dispatch to `setup.sh`: `uname -s` → select `macos` or `linux` tier; error clearly on an unsupported OS.
- [x] 3.2 Replace the in-place/skip-copy branch with symlink deploy of the active tier's app dirs into `~/.config` (backup-then-link) regardless of CWD, preserving clone-from-anywhere.
- [x] 3.3 Delegate to `<tier>/setup/.setup.sh`, each with its own `ORDER` (macOS: `brew` then `tweak`; Linux: `pacman yay flatpak app asdf tweak`); preserve drop-a-file extensibility within a tier.
- [x] 3.4 Preserve per-script logging (tee + `${PIPESTATUS[0]}`, delete-log-on-success, ✅/❌ summary) in each tier's runners, with `<script>.log` now living under `<tier>/setup/<module>/`.
- [x] 3.5 Keep root-refusal and Darwin Apple-CLT ensure in the top-level `setup.sh`.

## 4. Software provisioning (per-tier package managers)

- [x] 4.1 Scope the Homebrew bootstrap (install-if-missing + `eval shellenv`) to the macOS tier only (Darwin).
- [x] 4.2 Adopt `cachyos-home`'s existing Linux cascade wholesale under `linux/setup/` (`pacman`, `yay`, `flatpak`, `app`, `asdf`, `tweak`); confirm the `pacman` module bootstraps `yay` before the `yay` module runs, and that each provisioning module keeps one-script-per-package + per-package logs.
- [x] 4.3 Generalize the one-script-per-package model to "the active tier's mechanisms" (brew on macOS; pacman/yay/flatpak/asdf/app on Linux) while keeping failure isolation.
- [x] 4.4 Keep non-official-tap trust (`brew tap` + trust in-script) scoped to the macOS/brew module.

## 5. Reliability and idempotency

- [x] 5.1 Update truthful exit-code propagation: on partial failure `setup.sh` still symlinks configs (not copies) and still exits non-zero via `${PIPESTATUS[0]}`.
- [x] 5.2 Verify each tier's idempotent skip-check: macOS `brew list`/`brew list --cask`; Linux modules' existing checks (`pacman -Q`, `yay -Q`, `flatpak list`, asdf/app guards); confirm filename-minus-`.sh` equals the package leaf name wherever the check is name-based.
- [x] 5.3 Add and verify the "symlink deployment is idempotent and non-destructive" requirement (relink no-op; pre-existing real target backed up; nothing overwritten without backup; unmanaged entries untouched).
- [x] 5.4 Keep repo-scoped permission changes (limited to paths under the external repo) and extend: the symlink bootstrap must not chmod, delete, or overwrite unmanaged `~/.config` entries, and must exclude `.git`.
- [x] 5.5 Update ordering-safe tweaks so a tweak that runs before its `~/.config` symlink exists either operates on the in-tree source under `<tier>/` or ensures its target first.

## 6. Tracking and gitignore

- [x] 6.1 Replace the allowlist `.gitignore` with a conventional deny-list over the canonical repo root (task 1.2): `macos/`, `linux/`, `lib/`, `setup.sh`, `README.md`, `CLAUDE.md`, `.gitignore`.
- [x] 6.2 Enumerate and gitignore/fold per-app runtime/generated paths under the symlink hazard: at minimum `zsh/.zsh_history`, `zsh/*.zwc` (explicitly the self-compiled `zsh/.zshrc.zwc` written on every shell start), `micro/backups/`, `micro/buffers/`, `fish/fish_history`, generated `fish/completions/`; decide gitignore vs. per-file folding for each, with fold targets under `~/.local/state/<app>/` (or `~/.cache/<app>/` for pure caches).
- [x] 6.3 Verify no runtime/generated state is tracked and `git status` is clean after a shell start (i.e. the regenerated `.zshrc.zwc` does not appear).

## 7. Migration and rollback (existing mac + fresh machine)

- [ ] 7.1 Document and dry-run the fresh-machine path: `git clone <remote> ~/.dotfiles && ~/.dotfiles/setup.sh`; confirm unmanaged `~/.config` dirs are untouched.
- [x] 7.2 Existing-mac precondition: commit and push all pending `~/.config` state so no local-only history is lost.
- [x] 7.3 Apply the structured move on that history so `~/.dotfiles` carries the machine's latest state; verify before proceeding.
- [x] 7.4 Neutralize/retire `~/.config/.git` BEFORE running the symlink deploy on the in-place machine, so `~/.config` is no longer a working tree and the deploy cannot make git see managed dirs as deleted.
- [x] 7.5 Run `setup.sh` on the existing mac to back up and relink each managed `~/.config/<app>` via backup-then-link into `~/.dotfiles/macos/<app>`.
- [ ] 7.6 Verify rollback: for a sample app, remove the symlink and restore `<app>.bak.<ts>`; confirm the app reads the restored config.
- [ ] 7.7 Verify branch unification: confirm the single unified branch selects the correct tier per OS via `uname` and that no OS-specific file collides across tiers.

## 8. Documentation and post-migration audit

- [x] 8.1 Rewrite `CLAUDE.md` and `README.md` to describe the external `~/.dotfiles` + two-tier + symlink model: replace the copy-model, allowlist-`.gitignore`, `ORDER=(brew tweak)` single-cascade, and branch-per-OS ("main = macOS / cachyos-home = Linux, never merge wholesale") descriptions; document backup-then-link, `uname` dispatch, the per-tier `setup/` layout, and the runtime-state gitignore/fold rule.
- [x] 8.2 Update the graphify rule in `CLAUDE.md`/`.claude/CLAUDE.md` for the repo's new location (`~/.dotfiles`, no longer `~/.config`).
- [x] 8.3 Audit graphify auto-update hooks for any "repo == `~/.config`" assumption; verify they work with the working tree at `~/.dotfiles` (run after migration so the relocated `.git` exists).
- [x] 8.4 Audit `git-multi-account.zsh` (per-repo identity stamping) against the relocated working tree and symlinked configs; verify it still stamps the correct repo.
- [x] 8.5 Audit the `ai` alias and any other path-constant references; update if they assume the old location.
- [x] 8.6 Confirm nothing else depends on `~/.config/.git` existing.
- [ ] 8.7 Retain the pre-unification `main` and `cachyos-home` branches (and remote) until the unified branch is confirmed good on both machines; document their disposition and only retire after verification.
