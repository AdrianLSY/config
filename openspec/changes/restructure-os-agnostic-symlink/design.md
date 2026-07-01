## Context

The repository is a personal `~/.config` dotfiles set with a bootstrap installer. Its defining property today is that **the repo IS `~/.config`**: `.git` sits at `~/.config/.git`, and `setup.sh` deploys by destructively copying each managed dir into place (`rm -rf ~/.config/<dir> && cp -r <dir> ~/.config/`), skipping the copy when already run in place. That coupling forces an allowlist-style `.gitignore` (default-ignore `*`, then `!`-unignore each managed dir) purely to hide the many unmanaged app dirs that share the `~/.config` root (`gh`, `uv`, `raycast`, `configstore`, `cagent`, `tiger`, `git`, `openspec`, `projects`, `fish`, …).

Separately, the two machines live on two branches — `main` (macOS) and `cachyos-home` (Linux/Arch) — which have diverged by ~276 files and carry a standing "never merge wholesale" warning because `main` holds macOS-only config that breaks Linux. Measured overlap between them is tiny: different shells (zsh vs fish), zero-overlap window managers (aerospace vs hypr/waybar/…), different terminals (ghostty vs kitty), different package managers (brew vs yay), and different system tweaks. `micro/` is byte-identical; `zed/` is shared but `settings.json` differs by ~126 lines. The genuinely-shared surface is small.

This change restructures to an **external, tiered, symlink-deployed** repo. The canonical tracked repo root is `{ macos/, linux/, lib/, setup.sh, README.md, CLAUDE.md, .gitignore }`. Five decisions are locked by the user; this document records them and the technical rules that make them safe.

## Goals / Non-Goals

**Goals:**
- Move the repo out of `~/.config` to a standalone external path (canonically `~/.dotfiles`); `~/.config/<app>` becomes a symlink into the repo.
- Two OS tiers (`macos/`, `linux/`), OS chosen at runtime via `uname -s` — no branch-per-OS.
- Deploy by backup-then-link: never overwrite a real `~/.config` entry without a timestamped backup; relinking a correct symlink is a no-op; unmanaged `~/.config` dirs are untouched.
- Eliminate the allowlist `.gitignore` in favor of a conventional deny-list over tier-plus-`lib` content.
- Keep edit-live == edit-repo (symlinks preserve this; a copy/template tool would not).
- Adopt Linux provisioning wholesale from `cachyos-home`'s existing multi-module cascade (`pacman`/`yay`/`flatpak`/`app`/`asdf`/`tweak`), mirroring the brew model.
- Keep the runtime/generated-state-out-of-git guarantee under the new symlink hazard.

**Non-Goals:**
- No `common/`/`shared/` **config** tier. Duplicating identical config (`micro/`) and near-identical config (`zed/`) across tiers is an accepted consequence. (`lib/` is shared *bootstrap code*, not config — see Decision 2.)
- No per-host tier. The home-vs-work Linux split is dead; dispatch is pure OS (macos vs linux).
- No adoption of GNU Stow or chezmoi (see Decisions).
- No implementation shell scripts in this change — planning artifacts only.

## Decisions

### Decision 1 — External repo at `~/.dotfiles`, `~/.config/<app>` as symlinks
The repo relocates out of `~/.config` to an external path separate from `~/.config` (canonically `~/.dotfiles`); `.git` moves to `~/.dotfiles/.git`, and `~/.config` stops being a git working tree. Each managed app dir is deployed as a symlink `~/.config/<app>` → `~/.dotfiles/<tier>/<app>`.
- **Rationale:** kills the repo == `~/.config` coupling and the allowlist-`.gitignore` pain (the external repo contains only what we put there, so a conventional `.gitignore` suffices). Editing through the symlink is still a repo edit — no copy/sync step.
- **Note on the path:** `~/.dotfiles` is a convention, not a hard requirement; the hard requirement is that the repo is external, not `~/.config`.
- **Alternatives considered:** *Keep repo == `~/.config`* (status quo) — retains allowlist gymnastics and destructive-copy deploy; rejected.

### Decision 2 — Two OS tiers, no shared config tier
Repo has exactly two top-level tier dirs: `macos/` and `linux/`. Each holds its own app configs and its own `setup/`.
- **Rationale:** the package manager and nearly everything else differ per OS; measured overlap is tiny. A `common/` tier would add indirection for little payoff.
- **Accepted consequence:** identical config (`micro/`, byte-identical) is duplicated verbatim into both tiers; near-identical config (`zed/`) is duplicated with a per-tier `settings.json` (~126-line divergence), so `zed/` is not a clean duplication candidate the way `micro/` is. A change to a genuinely-shared file must be made in both tiers.
- **Escape hatch (sanctioned but not adopted now):** a single **in-repo, tier-to-tier symlink** (e.g. `linux/micro` → `../macos/micro`) if duplication ever stings — but *not* a whole `common/` tier. This intra-repo symlink is explicitly permitted by config-tracking as the de-duplication escape hatch.
- **`lib/` is not a config tier:** the symlink helper lives at repo root as `lib/link.sh`. It is a single shared *bootstrap-code* dir used by both tiers' `setup.sh`; it holds no app config, so it does not contradict the no-shared-config-tier decision.
- **Alternatives considered:** *A `common/`/`shared/` config tier* — rejected as not worth the indirection given tiny overlap. *chezmoi's single templated tier* — rejected (see Decision 5).

### Decision 3 — Option A tier layout: each OS owns its own `setup/`
Within a tier, everything for that OS lives together: app configs **and** that OS's bootstrap tooling under `<tier>/setup/`. macOS: `macos/setup/{brew,tweak}`. Linux: `linux/setup/{pacman,yay,flatpak,app,asdf,tweak}` (adopted wholesale from `cachyos-home`).
- **Rationale:** keeps one OS's full surface cohesive under one dir; tier selection picks up both configs and installers in one move.
- **Reserved-name rule:** within a tier, `setup/` is bootstrap tooling and is **never** symlinked into `~/.config`. Only app config dirs are deployed.
- **Alternatives considered (Option B):** a separated top-level `setup/<os>/` layout parallel to the config tiers — rejected; splits an OS's surface across two trees.

### Decision 4 — Backup-then-link conflict policy
When deploying `~/.config/<app>`:
- if it is already the correct symlink → **no-op**;
- elif it exists as a real dir/file **or** a wrong symlink → `mv` to `<app>.bak.<timestamp>`, then create the symlink;
- else → create the symlink.
Nothing is ever overwritten without a backup; unmanaged `~/.config` entries are never enumerated, touched, chmodded, or deleted.
- **Rationale:** safe and reversible on live machines. Rollback is `rm` the symlink and restore the `.bak.<ts>`.
- **Alternatives considered:** *Stow's refuse-on-conflict or `--adopt`* — refuse blocks migration on any pre-existing dir; `--adopt` pulls the live file *into* the repo (wrong direction, can pollute the repo with machine state). Neither matches the desired backup semantics — hence hand-rolled.

### Decision 5 — Hand-rolled Stow-inspired symlinker (`lib/link.sh`)
A small in-repo lib performs the backup-then-link logic; `setup.sh` calls it per app dir.
- **Rationale:** the exact policy (backup-then-link, idempotent relink) is not offered natively by any tool we surveyed.
- **Alternatives considered:** *GNU Stow* — essentially this design already (per-package symlink farming, supports per-file "folding"), but has **no native backup-then-link**: it refuses on conflict or uses `--adopt`. Rejected for that gap; its folding idea is borrowed for the runtime-state mitigation. *chezmoi* — copies+templates instead of symlinking (loses edit-live == edit-repo) and pushes toward one templated tier, contradicting Decision 2. Rejected.

### Decision 6 — Runtime-state hazard mitigation (whole-dir symlink folding / in-repo gitignore)
With whole-dir symlinks, an app that writes state into its config dir writes **through** the symlink into the repo working tree. Confirmed instances in this repo:
- **zsh** writes `.zsh_history` and, notably, **self-compiles** `.zshrc` into `.zshrc.zwc` in `$ZDOTDIR` (i.e. `zsh/`) on every shell start where `.zshrc` is newer than the `.zwc` — this is the single most frequent write-through and lands `zsh/.zshrc.zwc` inside the repo tree.
- **micro** writes `micro/backups/` and `micro/buffers/` (runtime state) alongside its tracked `settings.json`/`bindings.json`.
- **fish** (Linux tier) writes `fish/fish_history` and generated `completions/`.

**Rule:** runtime/generated paths under a symlinked app dir MUST be kept out of git by **(a)** gitignoring those paths within the repo, and/or **(b)** symlinking those particular subpaths per-file (Stow-style folding) so the volatile file resolves to a non-tracked location. The canonical fold target is a state dir **outside the tracked tree** — `~/.local/state/<app>/` (falling back to `~/.cache/<app>/` for pure caches). The mandatory enumeration for the apply phase includes at minimum: `zsh/.zsh_history`, `zsh/*.zwc` (esp. `zsh/.zshrc.zwc`), `micro/backups/`, `micro/buffers/`, `fish/fish_history`, `fish/completions/` (generated), plus per-app additions discovered during apply.
- **Rationale:** preserves the invariant that per-machine runtime state is never tracked, now enforced inside the repo rather than by the copy step.

### Decision 7 — OS dispatch inside bootstrap-orchestration, not a new capability
`setup.sh` first runs `uname -s` to pick the tier, then delegates to `<tier>/setup/.setup.sh` with that tier's `ORDER`. This is an extension of the existing cascading-runner model, so it belongs in **bootstrap-orchestration** — no new capability is created. The per-script logging mechanics (tee + `${PIPESTATUS[0]}`, delete-log-on-success, ✅/❌ summary) are unchanged, but the runners and their `<script>.log` files now live per-tier under `<tier>/setup/<module>/`.

### Decision 8 — Branch unification by structured move
The change collapses `main` (macOS) and `cachyos-home` (Linux) onto one branch by relocating each branch's dirs into its OS tier (`main` → `macos/`, `cachyos-home` → `linux/`). This is a **structured move** (`git mv` into tier dirs), not a wholesale merge, and is the safe resolution of the "never merge wholesale" footgun: OS-specific files never collide because they land in disjoint tier dirs, and OS selection becomes a runtime `uname` dispatch instead of a branch checkout.

## Risks / Trade-offs

- **[Risk] App state leaks into the repo through whole-dir symlinks — especially the zsh self-zcompile writing `zsh/.zshrc.zwc` on every shell start.** → Mitigate per Decision 6: gitignore runtime/generated paths within the repo (including `*.zwc`, `.zsh_history`, `micro/backups`, `micro/buffers`, `fish/fish_history`) and/or fold volatile subpaths to per-file symlinks pointing at `~/.local/state/<app>/`.
- **[Risk] Duplicated files (`micro/`, near-identical `zed/`) drift between tiers.** → Accepted per Decision 2; documented tradeoff. Escape hatch is a single intra-repo tier-to-tier symlink, not a `common/` tier.
- **[Risk] On the existing mac, symlinking a managed dir while `~/.config/.git` still exists makes git see every managed dir as deleted, risking a stray `git add .` committing deletions.** → Mitigate by ordering: on an in-place machine, commit/push pending state and apply the structured move so `~/.dotfiles` carries the latest history, then **retire `~/.config/.git` before** running the symlink deploy (see Migration Plan).
- **[Risk] Backup-then-link accumulates `<app>.bak.<ts>` clutter or a botched run half-links a tier.** → Timestamped, non-destructive backups make every step reversible; relink is idempotent so re-running finishes the job. A task audits leftover backups.
- **[Risk] Hooks/aliases assuming repo == `~/.config` break** (graphify auto-update, `git-multi-account.zsh` per-repo identity stamping, `ai` alias). → A dedicated audit, run after migration when the relocated `.git` exists, verifies each keeps working with the repo at `~/.dotfiles` and configs as symlinks; do not assume breakage, verify.
- **[Risk] Symlink deploy touches unmanaged `~/.config` dirs.** → Deploy iterates only the active tier's app dirs; unmanaged entries (`gh`, `uv`, `raycast`, …) are never enumerated, chmodded, or moved. Enforced by a bootstrap-reliability requirement.
- **[Trade-off] `uname`-only dispatch can't distinguish two Linux hosts.** → Accepted; per-host is a non-goal.

## Migration Plan

**Fresh machine (happy path):**
1. `git clone <remote> ~/.dotfiles`
2. `~/.dotfiles/setup.sh` — detects OS via `uname -s`, selects the tier, symlinks each tier app dir into `~/.config` (backup-then-link handles any pre-existing entry), then runs `<tier>/setup/.setup.sh` (macOS: brew → tweak; Linux: pacman → yay → flatpak → app → asdf → tweak).
3. Unmanaged `~/.config` dirs (`gh`, `uv`, `raycast`, …) are never touched.

**Existing mac (repo currently IS `~/.config` on `main`) — ordered for data safety:**
1. **Capture live state first:** commit and push all pending `~/.config` state so nothing local-only is lost.
2. Perform the structured move on that history (`git mv` `main`'s dirs into `macos/`, `cachyos-home`'s into `linux/`), producing the unified branch; verify `~/.dotfiles` reflects the machine's latest before proceeding.
3. Get the restructured repo to `~/.dotfiles`.
4. **Neutralize/retire the old `~/.config/.git` BEFORE any symlinking**, so `~/.config` is no longer a git working tree and the deploy cannot make git see managed dirs as deleted.
5. Run `~/.dotfiles/setup.sh`: each managed `~/.config/<app>` real dir is moved to `<app>.bak.<ts>` and replaced by a symlink into `~/.dotfiles/macos/<app>`.
6. Verify apps read correctly through the symlinks (with runtime-state paths gitignored/folded per Decision 6).

**Rollback (any machine):**
- For any app: remove the symlink `~/.config/<app>` and restore `<app>.bak.<ts>` in its place.
- Because backups are timestamped and nothing was overwritten in place, rollback is per-app and lossless. The pre-unification `main` and `cachyos-home` branches (and remote) are retained until the unified branch is confirmed good on both machines.

## Open Questions

- Whether `zed/` warrants the single-symlink escape hatch (Decision 2) given its ~126-line divergence, or stays fully duplicated with a per-tier `settings.json` (current plan).
- Final canonical remote/branch name for the unified branch, and the exact point at which the now-legacy `cachyos-home` branch is retired after unification is confirmed on both machines.
- Whether any additional per-app runtime paths beyond the Decision 6 enumeration need folding vs. gitignore — resolved during apply.
