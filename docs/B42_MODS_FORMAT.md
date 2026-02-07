
# docs/B42_MODS_FORMAT.md — Build 42 Mods Config Format (Project Zomboid Dedicated Server)

This document defines the **Build 42 (B42)** mod configuration format for this repository.

**Source of truth:** `data/Server/servertest.ini`

---

## 1) What Changed in Build 42

On many **Build 42 multiplayer/dedicated** setups, the `Mods=` line must use a **backslash-prefixed ModID** format:

✅ B42 style:
```

Mods=\ModA;\ModB;\ModC

```

Older/common B41 style (often not sufficient on B42 MP):
```

Mods=ModA;ModB;ModC

```

`WorkshopItems=` remains a **semicolon-separated list of numeric workshop IDs**:
```

WorkshopItems=111;222;333

````

---

## 2) The Two Required Fields

### 2.1 `WorkshopItems=` (Steam Workshop IDs)
- **Type:** numeric workshop IDs
- **Separator:** semicolon `;`
- **No spaces**
- Example:
```ini
WorkshopItems=3423660713;3640238758;3628421372
````

### 2.2 `Mods=` (ModIDs / internal mod identifiers)

* **Type:** Mod IDs (strings) – **NOT** workshop numbers
* **Separator:** semicolon `;`
* **B42 MP required format:** **each entry starts with `\`**
* Example:

```ini
Mods=\ModManager;\MyCoolFramework;\SomeMapMod
```

---

## 3) Consistency Rules (Must Hold)

### 3.1 Workshop download vs active load

* `WorkshopItems=` controls what the server **fetches/downloads**
* `Mods=` controls what the server **loads/enables**

**Rule:** A workshop mod should appear in both:

* its workshop ID in `WorkshopItems=...`
* its ModID in `Mods=...\ModID...`

### 3.2 Load order is significant

The order in `Mods=` is the **canonical mod load order**.
If two mods conflict, reordering in `Mods=` is a valid fix approach (but should be documented).

---

## 4) Common B42 Multiplayer Setting: Lua Checksum

Many B42 MP servers require disabling Lua checksum enforcement to prevent client mismatch errors:

```ini
DoLuaChecksum=false
```

**Policy in this repo:**

* If players get Lua mismatch errors / “file doesn’t exist” / checksum-type failures, verify or set:

  * `DoLuaChecksum=false`
* Document the change in `docs/CHANGELOG.md`.

---

## 5) Examples

### 5.1 Minimal valid B42 mod config

```ini
WorkshopItems=3423660713
Mods=\ModManager
DoLuaChecksum=false
```

### 5.2 Multiple mods (B42)

```ini
WorkshopItems=3423660713;3640238758;3628421372
Mods=\ModManager;\SomeDependency;\MyMainMod
DoLuaChecksum=false
```

---

## 6) Validation Checklist (Codex / Operator)

After any mod list change:

1. Confirm `WorkshopItems=` contains only numbers separated by `;`
2. Confirm `Mods=` contains ModIDs separated by `;` and **each starts with `\`**
3. No commas, no spaces, no newlines inside the value
4. Restart server
5. Check `data/Logs/*DebugLog-server.txt` for:

   * missing mod/workshop item
   * init/Lua errors during mod load
   * map/tile/registry conflicts
6. If errors repeat: revert (`git revert` + restore backup).

---

## 7) Common Failure Patterns

* **Using Workshop ID in `Mods=`**

  * Wrong: `Mods=\3423660713`
  * Correct: `Mods=\ModManager`

* **Missing backslashes in B42 MP**

  * Risky: `Mods=ModManager;MyMainMod`
  * Preferred: `Mods=\ModManager;\MyMainMod`

* **Mismatch between `WorkshopItems` and `Mods`**

  * Result: downloaded but not loaded, or load fails.

---

## 8) Notes

B42 is fast-moving. If a future B42 patch changes expected formatting or introduces new fields:

* update this document
* update `AGENTS.md` “Build 42 Mod List Format” section
* record in `docs/CHANGELOG.md` under “Build Updates (B42)”

```

If you want it, I can also write a companion `docs/MODS_TROUBLESHOOTING.md` with “symptom → log pattern → fix” for the most common B42 mod load failures.
::contentReference[oaicite:0]{index=0}

