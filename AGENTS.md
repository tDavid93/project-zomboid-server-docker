# AGENTS.md — Project Zomboid Modded Server (Codex Operating Manual)

This repository is a **modded Project Zomboid build 42 dedicated server** managed via Docker Compose.
Codex is expected to:
- configure the server safely and reproducibly
- diagnose crashes / mod issues using logs + config
- tune gameplay based on player feedback (small, testable iterations)
- keep everything versioned and rollbackable

Repository snapshot (canonical paths):
- Runtime configs: `data/Server/servertest.ini`, `data/Server/servertest_SandboxVars.lua`, `data/Server/*spawn*.lua`
- Persistent data: `data/Saves/Multiplayer/`, `data/db/servertest.db`, `data/Workshop/`, `data/mods/`
- Logs: `data/Logs/`, `data/server-console.txt`
- Infra: `docker-compose.yml`, `Dockerfile`, `scripts/`
- Mods staging: `workshop-mods/` (Steam workshop cache), `local-mods/` (non-workshop mods)

---

## 1) Safety Rules (Non-Negotiable)

### 1.1 Never Lose Player Data
Codex MUST NOT delete or reset:
- `data/Saves/Multiplayer/`
- `data/db/servertest.db`
- `data/Workshop/` / `data/mods/`
unless the task explicitly says “wipe/clear world”.

If a task involves anything risky, Codex must:
1) create a backup into `data/backups/`
2) document rollback steps in the PR/commit message and/or `README.MD`

### 1.2 Small Changes, One Variable at a Time
For gameplay tuning and stability:
- change **1–3 settings per iteration**
- restart and validate using logs
- record results in `docs/FEEDBACK.md` (create if missing)

### 1.3 Reproducibility
All changes must be encoded in repo-tracked files:
- configs in `data/Server/`
- scripts in `scripts/`
- compose/runtime in `docker-compose.yml`
No “hand edits on host” without committing the equivalent change.

---

## 2) Canonical Configuration Files (Source of Truth)

### 2.1 Server INI (connections/modlists/server rules)
`data/Server/servertest.ini`

This is the primary place for:
- server name, ports, public settings
- `Mods=` and `WorkshopItems=` (must remain consistent)
- general server options

### 2.2 Sandbox gameplay rules (Lua table)
`data/Server/servertest_SandboxVars.lua`

This defines most gameplay tuning:
- zombies, loot rarity, infection, farming, vehicles, etc.

### 2.3 Spawn settings
- `data/Server/servertest_spawnregions.lua`
- `data/Server/servertest_spawnpoints.lua`

Codex should treat these as “surgical edit” files (small, careful changes).

---

## 3) How Codex Should Operate This Repo

### 3.1 Primary Interfaces
Codex should use and improve existing scripts first:
- `scripts/entry.sh` (container entry)
- `scripts/get_updates.sh`, `scripts/update_mods.sh` (update mechanics)
- `scripts/mod_manager.py` (mod list + workshop handling)
- `scripts/clear_world.sh` (world wipe tooling — dangerous)

If a task asks “configure server”, Codex should prefer to implement changes by:
1) updating `data/Server/*.ini` and `*_SandboxVars.lua`
2) keeping mod lists consistent via `scripts/mod_manager.py` (or improving it)
3) updating compose/env only if necessary

### 3.2 Observability: Always Look at Logs First
Primary log sources:
- `data/Logs/*DebugLog-server.txt` (best for mod/load errors)
- `data/Logs/*_user.txt` and `*_chat.txt`
- `data/server-console.txt`
- `data/Logs/logs_YYYY-MM-DD/` folders

When debugging:
- capture the relevant log excerpt
- identify which mod or config line caused the issue
- fix minimally, then validate by restarting and re-checking logs

---

## 4) Backup & Rollback Discipline

### 4.1 Backups Location
All backups go under: `data/backups/`

Codex should ensure there is (or create) a script:
- `scripts/backup.sh`  → creates timestamped tar/zip under `data/backups/`
- `scripts/restore.sh` → restores a selected backup (documented usage)

Minimum backup contents for risky operations:
- `data/Server/`
- `data/Saves/Multiplayer/`
- `data/db/servertest.db`
- mod state directories used by this setup (`data/mods/`, `data/Workshop/`, and/or `workshop-mods/` depending on wiring)

### 4.2 Rollback Checklist (every risky change)
Every mod change or gameplay overhaul must include:
- backup name / timestamp
- exact files changed
- restart steps
- rollback steps (git revert + restore backup)

---

## 5) Mods & Workshop Rules

### 5.1 Consistency Requirements
If using workshop mods, `servertest.ini` typically includes:
- `WorkshopItems=...` (workshop IDs)
- `Mods=...` (mod IDs)

Codex must keep these consistent:
- adding a workshop item without its corresponding mod ID is invalid
- changing load order may fix conflicts; document it

### 5.2 Local Mods
Local mods live in `local-mods/`.
If local mods are used by the server, Codex should confirm how they are mounted / referenced (compose + scripts) and keep that consistent.

### 5.3 Update Policy
Default assumption:
- DO NOT auto-update mods on every start if stability matters.
- Use `scripts/get_updates.sh` / `scripts/update_mods.sh` deliberately.
If a task asks for “auto update”, Codex must implement it with:
- a toggle env var
- a “lock” or “pinned version” option if feasible
- a pre-update backup

### 5.5 Build 42 Mods Config Format (Mandatory Reference)
Build 42 multiplayer/dedicated setups commonly require a different `Mods=` format than B41.

**Codex MUST follow the format rules defined here:**
- `docs/B42_MODS_FORMAT.md`

Repository policy for B42:
- `WorkshopItems=` is a semicolon-separated list of numeric workshop IDs.
- `Mods=` is a semicolon-separated list of ModIDs, and on B42 MP it should use the
  **backslash-prefixed entry format**:
  - Example: `Mods=\ModA;\ModB;\ModC`
- Mod load order is the order in `Mods=`.
- If clients fail with Lua mismatch/checksum-type issues, verify:
  - `DoLuaChecksum=false`


---

## 6) “Configure the Server” Requirement (Codex Must Be Able To Tune)

Codex should provide a single, safe entry-point for configuration changes.

Preferred: add/maintain `scripts/configure.py` that can:
- read a profile file (YAML/JSON) from `profiles/*.yaml`
- update:
  - `data/Server/servertest.ini`
  - `data/Server/servertest_SandboxVars.lua`
- supports:
  - `--dry-run` (prints diffs)
  - `--apply`
  - `--backup` (default on for apply)
  - `--set key=value` overrides for quick tweaks

If this script doesn’t exist, Codex should create it when asked to “make Codex configurable”.

---

## 7) SandboxVars.lua Editing Rules (Avoid Regex Hell)

`servertest_SandboxVars.lua` is Lua. Codex must NOT do fragile regex edits that can break structure.

Preferred approaches:
- Use a Lua parser (best) OR a tolerant “table key patcher” that:
  - finds `SandboxVars = { ... }`
  - updates only specific key paths
  - preserves formatting as much as possible
  - does not reorder unrelated blocks

Any tool Codex adds must:
- validate output is still valid Lua table syntax
- keep diffs minimal

---

## 8) Feedback Loop (Gameplay Fine-Tuning)

Codex should maintain:
- `docs/FEEDBACK.md` (create if missing)

Template entry:
- Date
- Reporter(s)
- Problem (“too many insta-deaths”, “loot too scarce”, “cars too common”, etc.)
- Hypothesis
- Changes (exact vars + old → new)
- Trial window (sessions/dates)
- Result
- Next step

Codex should also maintain:
- `docs/CHANGELOG.md` (create if missing) with sections:
  - Gameplay
  - Mods
  - Infrastructure
  - Fixes

---

## 9) Standard Task Execution Patterns

### 9.1 Bugfix / Crash
1) locate log lines in `data/Logs/*DebugLog-server.txt`
2) identify mod/config cause
3) minimal fix
4) restart + confirm no repeating error
5) document in `CHANGELOG.md` + runbook notes if needed

### 9.2 Gameplay Tune
1) translate feedback → 1–3 variables
2) backup
3) apply changes (prefer via `scripts/configure.py` if present)
4) restart
5) log “trial plan” in `FEEDBACK.md`

### 9.3 Mod Add/Remove/Reorder
1) backup
2) update `WorkshopItems` + `Mods` (prefer via `mod_manager.py`)
3) ensure dependencies present
4) restart
5) verify in logs that all mods loaded successfully

---

## 10) Wipe / Clear World Guardrails

The script `scripts/clear_world.sh` is dangerous.
Codex must treat it as “explicit-only”.
If a task requests a wipe:
- backup first (always)
- clearly list what will be deleted/reset
- ensure mod state is consistent after wipe

---

## 11) Definition of “Done”
A change is “done” only if:
- configs remain valid (ini + lua)
- server starts successfully
- no repeating errors in the latest DebugLog
- changes are documented (changelog + feedback if gameplay related)
- rollback exists (backup + instructions)

---
