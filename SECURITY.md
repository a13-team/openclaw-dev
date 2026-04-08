# Security Audit Report — openclaw-dev

**Repository:** `W:\OpenClaw\openclaw-dev`
**Audit Date:** 2026-04-07
**Auditor:** validator agent
**Status:** ✅ PASS — No critical issues found

---

## 1. Scope

| Area | Files Checked |
|------|---------------|
| Install/Uninstall scripts | `install.sh`, `install.ps1`, `uninstall.sh`, `uninstall.ps1` |
| Security scanning | `scripts/security-scan.sh`, `scripts/security-scan.ps1` |
| Git hooks | `hooks/git/pre-commit`, `hooks/git/pre-push` |
| Linting | `scripts/skill-lint.sh` |
| Skills | 4 skill packages (knowledgebase, skill-dev, node-ops, model-routing) |
| Commands | 8 command files (diagnose, setup-node, lint-config, evolve-skill, create-skill, deploy-skill, validate-skill, list-skills) |
| Config | `.gitignore` |

---

## 2. Hardcoded Secrets Scan

### Patterns Searched
- `sk_` (OpenAI keys)
- `ghp_`, `ghs_`, `gho_` (GitHub tokens)
- `hf_` (HuggingFace tokens)
- `AKIA*` (AWS keys)
- `xoxb-`, `xoxp-` (Slack tokens)
- `TOKEN=`, `SECRET=`, `PASSWORD=`, `API_KEY=` with non-placeholder values
- `BEGIN .*(PRIVATE KEY|CERTIFICATE)`

### Results

**✅ No real secrets found.** All matches were:

| Type | Example | Location | Risk |
|------|---------|----------|------|
| Whitelist patterns | `sk-[a-zA-Z0-9]{20,}` | `security-scan.sh` (detection rule, not a secret) | None |
| Placeholder values | `<token>`, `<key>`, `your_api_key` | SKILL.md files | None |
| Example strings | `example.com`, `localhost`, `127.0.0.1` | Multiple docs/runbooks | None |
| Placeholder paths | `/Users/xxx`, `C:\Users\` | SKILL.md anti-pattern documentation | None |
| Generic variable names | `${API_KEY}`, `${TOKEN}` in bash parameter expansion | `diagnose.md`, `setup-node.md` | None — bash env var syntax |

---

## 3. Install/Uninstall Scripts

### install.sh — Assessment: ✅ SAFE

| Check | Result |
|-------|--------|
| Dangerous commands | ⚠️ Uses `rm -rf` but only inside `sync_manifest()` to clean target skill dirs before copy. Controlled, non-recursive outside target. |
| External URL fetching | ✅ `curl -fsSL https://openclaw.ai/install.sh` — verified HTTPS endpoint |
| Base64 payloads | None found |
| Shell injection | ✅ All variables quoted (`"$target"`, `"$source_dir"`). Path args passed as discrete parameters, not concatenated into strings. |
| Destructive operations | None beyond managed skill sync |

### install.ps1 — Assessment: ✅ SAFE

| Check | Result |
|-------|--------|
| Dangerous commands | ⚠️ Uses `Remove-Item -Recurse -Force` but only in `Copy-Skills` to clean before copy. Controlled. |
| External URL fetching | ✅ `iwr -useb https://openclaw.ai/install.ps1` — verified HTTPS endpoint |
| Base64 payloads | None found |
| Injection risks | Low — PowerShell parameter binding is safe |
| Destructive operations | None beyond managed skill sync |

### uninstall.sh — Assessment: ✅ SAFE

| Check | Result |
|-------|--------|
| Dangerous commands | `rm -rf` used only for confirmed openclaw skill directories. Uses `remove_installed()` which checks `SKILL.md` presence before deletion. |
| Target validation | ✅ `remove_installed()` verifies path is an openclaw install before removing |
| Dry-run support | ✅ `--dry-run` flag prevents actual deletion |
| Whitelist validation | ✅ Only removes files matching openclaw skill keywords |
| Destructive operations | Contained and validated |

### uninstall.ps1 — Assessment: ✅ SAFE

| Check | Result |
|-------|--------|
| Dangerous commands | Same pattern as uninstall.sh — `Remove-Item` only after SKILL.md verification |
| Target validation | ✅ `Remove-Installed` checks for SKILL.md before removal |
| Dry-run support | ✅ `-DryRun` switch |
| Destructive operations | Contained and validated |

---

## 4. Security Scanning Scripts

### scripts/security-scan.sh — Assessment: ✅ WELL-DESIGNED

**Strengths:**
- Comprehensive pattern coverage: path leaks, secrets, privacy info (emails, IPs, private keys), and identity strings
- Extensive context-aware whitelisting to reduce false positives
- Reads from git staged content (not working tree) in pre-commit context
- Supports `--strict` flag for CI enforcement
- Identity patterns loaded from `.security-identities` file (per-contributor, not committed)
- Skips binary files, platform dirs (`.claude/`, `.codex/`, etc.), and lock files

**Whitelist Quality:**
- Path whitelist handles diagnostic guidance text, placeholder paths, grep command examples
- Privacy whitelist handles private IP ranges (10.x, 192.168.x, 172.16-31.x, 169.254.x, 100.64.x) with documentation context
- Secret whitelist handles common placeholder strings (`changeme`, `xxx`, `<token>`, etc.)

### scripts/security-scan.ps1 — Assessment: ✅ PARITY WITH SH

Parity with `security-scan.sh`: same patterns, same whitelist logic, same skip list. ✅

---

## 5. Git Hooks

### hooks/git/pre-commit — Assessment: ✅ SAFE (READ-ONLY)

| Check | Result |
|-------|--------|
| Destructive operations | ✅ None — only reads staged content via `git show` |
| Modifications | ✅ None — purely additive (logs violations, exits 1 on failure) |
| Bypass available | ✅ `git commit --no-verify` works |
| Scanning scope | ✅ Staged files only, not full working tree |
| Patterns | Basic subset of security-scan.sh (path leaks + secrets only) |

**Note:** Pre-commit uses a subset of patterns (not full privacy/identity checks). This is acceptable for staged-file scanning speed.

### hooks/git/pre-push — Assessment: ✅ SAFE (READ-ONLY)

| Check | Result |
|-------|--------|
| Destructive operations | ✅ None |
| Modifications | ✅ None |
| Bypass available | ✅ `git push --no-verify` works |
| CI parity | ✅ Runs `security-scan.sh --strict` and `skill-lint.sh` — mirrors CI |
| Blocks on failure | ✅ Exit 1 prevents push |

---

## 6. scripts/skill-lint.sh — Assessment: ✅ SAFE (READ-ONLY)

- No destructive operations
- Reads SKILL.md files only for validation
- Detects anti-patterns (hardcoded paths, stale command references)
- Cross-reference check searches for old command names in skills/ and commands/ dirs

---

## 7. Overall Risk Assessment

| Category | Risk Level | Notes |
|----------|-----------|-------|
| Secrets exfiltration | **NONE** | No real secrets in codebase |
| Script injection | **LOW** | install.sh/inject have proper quoting; PowerShell has native parameter binding |
| Destructive ops | **LOW** | All `rm`/`Remove-Item` calls are target-controlled and validated |
| Path disclosure | **LOW** | `.gitignore` excludes `.security-identities`, `data/signals.json`, `docs/plans/`, `*.local.md`, `.env*` |
| External fetches | **NONE** | Only fetches from `https://openclaw.ai/` via HTTPS |
| Hook safety | **NONE** | Both hooks are read-only, non-blocking bypass available |

---

## 8. Recommendations

### Already Implemented ✅
1. `.security-identities` file for personal identity patterns — not committed to repo
2. `docs/plans/` and `data/signals.json` in `.gitignore` — shields personal info
3. `*.local.md` and `.env*` in `.gitignore` — shields local config
4. Manifest-based sync in install/uninstall — precise cleanup, no overwriting
5. Dry-run support in uninstall scripts
6. Read-only git hooks with `--no-verify` bypass

### Suggested Improvements (Non-Critical)

| # | Suggestion | Priority |
|---|-----------|----------|
| 1 | Add `.security-identities.example` to repo so contributors know to create their own | Low |
| 2 | `install.sh` uses `set -euo pipefail` — consider adding `set -n` (noop parse test) as a pre-install sanity check | Low |
| 3 | Consider adding `--verify-only` flag to install scripts (show what would be installed without installing) | Low |
| 4 | Pre-commit hook could include privacy/identity checks for parity with security-scan.sh | Low |
| 5 | Add `hooks/` directory to `.gitignore` locally (hooks are copied, not referenced from repo `.git/hooks/`) | Info only |

---

## 9. Security Best Practices Used

| Practice | Evidence |
|----------|----------|
| No hardcoded secrets | All API key patterns are detection rules, not actual keys |
| Principle of least privilege | Uninstall scripts verify skill identity before removing |
| Defense in depth | Multiple layers: pre-commit scan → pre-push full scan → CI gate |
| Safe file operations | `cp -rp` with error handling, not `mv` or raw overwrite |
| Input validation | All user inputs quoted and validated |
| Idempotent operations | `sync_manifest()` handles already-installed states gracefully |
| Audit trail | `security-scan.sh` logs violations with file:line:content |
| Bypass for emergencies | `--no-verify` on git commit/push, `--dry-run` on uninstall |

---

## 10. Conclusion

**✅ Audit Result: PASS**

The openclaw-dev repository implements sound security practices across its tooling. No hardcoded secrets, no dangerous shell operations without validation, and no exfiltration risks. The security scanning infrastructure is comprehensive and well-whitelisted against false positives.

The only operational risk is the inherent nature of install scripts modifying user home directories — but this is by design and is the primary purpose of the tool.

**No blocking issues. No remediation required.**
