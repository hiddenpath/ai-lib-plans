# PT-073g — Conflict resolution runbook (GOV-002)

> **Rule**: `ai-lib-constitution/rules/governance/GOV-002-merge-conflict-resolution-discipline.yaml`  
> **Scope**: Multi-executor sync, merge/rebase, and audit report commits on PT-073g repos.

---

## 1. When this applies

| Situation | Auto-sync stops | Action |
|-----------|-----------------|--------|
| Private `lan/main` and `origin/main` **both ahead** (true divergence) | Yes | §2 |
| Public `main` **ahead and behind** `origin/main` with **non-empty tree diff** | Yes | §3 |
| Merge/rebase in progress (`MERGE_HEAD`, conflict markers) | Yes | §4 |
| Fast-forward only (one side ahead, same ancestry) | No | Script may push or reset |

**Forbidden**: `git checkout --ours/--theirs` on whole files; `reset --hard` when both sides carry unique commits with different content; leaving `<<<<<<<` markers in committed files.

---

## 2. Private dual-remote divergence (plans / constitution / eos)

**GOV-004**: `lan` is daily truth; `origin` is backup. When both remotes diverged:

1. `git fetch --all --prune`
2. Inspect both sides (no blind pick):
   ```bash
   git log --oneline --left-right lan/main...origin/main
   git diff lan/main...origin/main --stat
   ```
3. Checkout `main`, merge **prefer `lan/main` as first parent**:
   ```bash
   git checkout main
   git merge lan/main -m "sync: merge lan/main (GOV-002 PT-073g)"
   git merge origin/main   # resolve conflicts per §5 if any
   ```
4. Resolve conflicts at **block/function** level; cite task YAML or audit doc intent.
5. Verify no conflict markers: `rg '<<<<<<<|=======|>>>>>>>'`
6. Push **both** remotes after review:
   ```bash
   git push lan main
   git push origin main
   ```
7. Record in `completion_notes` or audit log: paths conflicted, sides, rationale.

---

## 3. Public runtime repos (ailib-official)

Auditors should **not** carry local commits on `main`. Sync script allows `reset --hard origin/main` only when:

- `git diff origin/main..HEAD` is **empty** (history-only divergence, e.g. post-squash), or
- `HEAD` is strictly behind `origin/main` (fast-forward).

If `git diff origin/main..HEAD` is **non-empty**:

1. **Do not** `reset --hard`.
2. Stash or branch local work: `git stash push -m "PT-073g pre-sync"` or `git checkout -b audit/local-wip`
3. `git fetch origin && git checkout main && git merge origin/main` (or rebase per team norm).
4. Resolve per **GOV-002** + **ARCH-003** (prefer protocol + Rust reference for parity conflicts).
5. Land fix via **PR** to `ailib-official`; update `PT-073g-SYNC_BASELINE.md` §2 after merge.

---

## 5. Conflict resolution checklist (GOV-002)

- [ ] Read both sides; smallest meaningful merge unit
- [ ] Align with protocol / task intent / `PT-073g` YAML
- [ ] Preserve proxy, `trust_env`, compliance CI, E/P boundaries
- [ ] No `hiddenpath/*` URLs in public repo workflows (GOV-001)
- [ ] Run narrow tests on touched execution paths (TEST-001)
- [ ] PR or maintainer note: paths, sides, rationale
- [ ] No conflict markers in repo

---

## 6. Script behavior

`sync_pt073g_repos.ps1` / `.sh`:

- **Exits 1** on true divergence (prints this runbook path).
- Does **not** force-push.
- Public repos: `reset --hard` only when tree matches `origin/main` or FF-only behind.
- **Skips `reset`** when working tree has uncommitted changes (commit/stash first).

See also: [PT-073g-SYNC_BASELINE.md](./PT-073g-SYNC_BASELINE.md)
