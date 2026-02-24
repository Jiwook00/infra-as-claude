Sync documentation to reflect recent activity and current infrastructure state.

## What to do

### 1. Read recent activity

Check `logs/activity.log` for the last 50 entries. Identify:
- Which AWS resources were queried or modified
- Any new resources added or removed (compare with `state/` snapshots)
- Dates of significant changes

### 2. Update CHANGELOG.md

Append a new entry at the top of `CHANGELOG.md` in this format:

```markdown
## [YYYY-MM-DD]

### Added
- ...

### Changed
- ...

### Removed
- ...
```

Only include entries for meaningful changes (not routine queries).

### 3. Sync commands-reference.md

Scan `.claude/commands/` for all command files. Update `docs/commands-reference.md` to reflect:
- Any new commands added
- Any commands that were modified
- Current command list and descriptions

### 4. Update README.md infrastructure summary

If `state/` contains recent snapshots, update the **"Current Infrastructure"** section in `README.md` (if it exists) with the latest resource counts.

### 5. Confirm

Print a brief summary of what was updated:

```
✓ CHANGELOG.md  — added entry for 2025-01-15
✓ commands-reference.md — synced (6 commands)
✓ README.md — no updates needed
```
