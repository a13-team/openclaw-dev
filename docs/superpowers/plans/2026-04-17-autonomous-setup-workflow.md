# Autonomous Setup Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete autonomous setup workflow for the repository with a new execution-layer skill, user-facing entry commands, narrow validation, and a repaired QA runner.

**Architecture:** Keep `openclaw-autonomous-setup` as the orchestration layer and add `openclaw-self-configurator` as the execution layer. Validate bundle integrity through a lightweight shell validator and restore the QA runner contract already referenced throughout the repo.

**Tech Stack:** Markdown command/skill bundles, Bash validation scripts, repo-local shell tests, existing `scripts/skill-lint.sh`

---

### Task 1: Add a failing workflow regression test

**Files:**
- Create: `tests/autonomous-setup-workflow.sh`
- Test: `tests/autonomous-setup-workflow.sh`

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

required_files=(
  "$ROOT/commands/setup-autonomous.md"
  "$ROOT/commands/validate-autonomous-setup.md"
  "$ROOT/skills/openclaw-self-configurator/SKILL.md"
  "$ROOT/scripts/validate-autonomous-setup.sh"
  "$ROOT/plugins/qa/scripts/run-qa-tests.sh"
)

for path in "${required_files[@]}"; do
  [[ -f "$path" ]] || {
    echo "MISSING: $path"
    exit 1
  }
done

bash "$ROOT/scripts/validate-autonomous-setup.sh" --check-only
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/autonomous-setup-workflow.sh`
Expected: FAIL with `MISSING:` for the first absent workflow file.

- [ ] **Step 3: Write minimal implementation**

Create the missing files with placeholder-valid content only after the test has failed, then expand them in later tasks.

- [ ] **Step 4: Run test to verify it still exercises the workflow**

Run: `bash tests/autonomous-setup-workflow.sh`
Expected: It now fails deeper inside `scripts/validate-autonomous-setup.sh` until the wiring is complete.

- [ ] **Step 5: Commit**

```bash
git add tests/autonomous-setup-workflow.sh
git commit -m "test: add autonomous setup workflow regression"
```

### Task 2: Add the validation command and validator

**Files:**
- Create: `commands/validate-autonomous-setup.md`
- Create: `scripts/validate-autonomous-setup.sh`
- Test: `tests/autonomous-setup-workflow.sh`

- [ ] **Step 1: Write the failing validator expectation into the test**

```bash
grep -q 'validate-autonomous-setup' "$ROOT/README.md" || {
  echo "README missing validate-autonomous-setup"
  exit 1
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/autonomous-setup-workflow.sh`
Expected: FAIL due to missing validator command or README wiring.

- [ ] **Step 3: Write minimal implementation**

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHECK_ONLY="${1:-}"
failures=0

check_file() {
  local path="$1"
  [[ -f "$path" ]] || {
    echo "FAIL missing file: $path"
    failures=$((failures + 1))
  }
}

check_file "$ROOT/commands/setup-autonomous.md"
check_file "$ROOT/commands/validate-autonomous-setup.md"
check_file "$ROOT/skills/openclaw-autonomous-setup/SKILL.md"
check_file "$ROOT/skills/openclaw-self-configurator/SKILL.md"
check_file "$ROOT/plugins/qa/scripts/run-qa-tests.sh"

if [[ "$CHECK_ONLY" != "--check-only" ]]; then
  bash "$ROOT/scripts/skill-lint.sh" "$ROOT/skills/openclaw-autonomous-setup"
  bash "$ROOT/scripts/skill-lint.sh" "$ROOT/skills/openclaw-self-configurator"
  bash "$ROOT/scripts/skill-lint.sh" "$ROOT/skills/clawhub-skill-installer"
fi

(( failures == 0 ))
```

- [ ] **Step 4: Run test to verify it passes this stage**

Run: `bash tests/autonomous-setup-workflow.sh`
Expected: PASS for file existence and validator wiring once the command/script exist.

- [ ] **Step 5: Commit**

```bash
git add commands/validate-autonomous-setup.md scripts/validate-autonomous-setup.sh tests/autonomous-setup-workflow.sh
git commit -m "feat: add autonomous setup validation entrypoint"
```

### Task 3: Add the execution-layer self-configuration skill and setup command

**Files:**
- Create: `skills/openclaw-self-configurator/SKILL.md`
- Create: `skills/openclaw-self-configurator/references/self-config-blueprint.md`
- Create: `skills/openclaw-self-configurator/references/self-config-checklist.md`
- Create: `skills/openclaw-self-configurator/references/recommended-skill-packs.md`
- Create: `commands/setup-autonomous.md`
- Modify: `skills/openclaw-autonomous-setup/SKILL.md`

- [ ] **Step 1: Write the failing test for execution-layer references**

```bash
for path in \
  "$ROOT/skills/openclaw-self-configurator/references/self-config-blueprint.md" \
  "$ROOT/skills/openclaw-self-configurator/references/self-config-checklist.md" \
  "$ROOT/skills/openclaw-self-configurator/references/recommended-skill-packs.md"
do
  [[ -f "$path" ]] || {
    echo "MISSING reference: $path"
    exit 1
  }
done
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/autonomous-setup-workflow.sh`
Expected: FAIL with `MISSING reference: ...`.

- [ ] **Step 3: Write minimal implementation**

```markdown
---
name: openclaw-self-configurator
description: "Use this skill when an approved OpenClaw target state must be turned into a concrete self-configuration rollout pack with topology, config skeletons, validation, and repair guidance."
metadata: {"clawdbot":{"always":false,"emoji":"🛠️"}}
user-invocable: true
version: 1.0.0
---
```

Add a concise body that points to the three reference files and defines the execution-layer workflow. Update `openclaw-autonomous-setup` to delegate to this skill after target-state design. Add `setup-autonomous` as the user-facing command that ties them together.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/autonomous-setup-workflow.sh`
Expected: PASS for execution-layer file coverage.

- [ ] **Step 5: Commit**

```bash
git add skills/openclaw-self-configurator commands/setup-autonomous.md skills/openclaw-autonomous-setup/SKILL.md tests/autonomous-setup-workflow.sh
git commit -m "feat: add self-configurator workflow layer"
```

### Task 4: Restore the canonical QA runner

**Files:**
- Create: `plugins/qa/scripts/run-qa-tests.sh`
- Modify: `plugins/qa/AGENTS.md`
- Modify: `plugins/qa/scripts/codex-diagnose.sh`
- Modify: `commands/qa-agent.md` if command wording needs alignment
- Test: `tests/autonomous-setup-workflow.sh`

- [ ] **Step 1: Write the failing test for QA runner behavior**

```bash
bash "$ROOT/plugins/qa/scripts/run-qa-tests.sh" --quick >/dev/null 2>&1 || {
  echo "QA quick mode failed"
  exit 1
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/autonomous-setup-workflow.sh`
Expected: FAIL because `run-qa-tests.sh` does not exist or exits non-zero.

- [ ] **Step 3: Write minimal implementation**

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
MODE="--quick"

for arg in "$@"; do
  case "$arg" in
    --quick|--full) MODE="$arg" ;;
  esac
done

mkdir -p "$ROOT/plugins/qa/reports"
report="$ROOT/plugins/qa/reports/qa-report-$(date +%Y%m%d-%H%M%S).md"

{
  echo "# QA Report"
  echo
  echo "- Mode: $MODE"
  echo "- Runner: plugins/qa/scripts/run-qa-tests.sh"
} > "$report"

bash "$ROOT/scripts/validate-autonomous-setup.sh" --check-only
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/autonomous-setup-workflow.sh`
Expected: PASS and a new report under `plugins/qa/reports/`.

- [ ] **Step 5: Commit**

```bash
git add plugins/qa/scripts/run-qa-tests.sh plugins/qa/AGENTS.md plugins/qa/scripts/codex-diagnose.sh
git commit -m "fix: restore autonomous QA runner entrypoint"
```

### Task 5: Sync documentation and instructions

**Files:**
- Modify: `README.md`
- Modify: `.github/copilot-instructions.md`
- Modify: `.github/prompts/openclaw-autonomous-setup.prompt.md`
- Modify: `.github/instructions/openclaw-autonomy.instructions.md`
- Modify: `skills/openclaw-autonomous-setup/references/openclaw-setup-research.md`
- Test: `tests/autonomous-setup-workflow.sh`

- [ ] **Step 1: Write the failing documentation assertions**

```bash
for path in \
  "$ROOT/README.md" \
  "$ROOT/.github/copilot-instructions.md" \
  "$ROOT/.github/prompts/openclaw-autonomous-setup.prompt.md" \
  "$ROOT/.github/instructions/openclaw-autonomy.instructions.md"
do
  grep -q 'setup-autonomous' "$path" || {
    echo "Missing setup-autonomous in $path"
    exit 1
  }
  grep -q 'validate-autonomous-setup' "$path" || {
    echo "Missing validate-autonomous-setup in $path"
    exit 1
  }
done
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/autonomous-setup-workflow.sh`
Expected: FAIL on the first doc that does not name both entrypoints.

- [ ] **Step 3: Write minimal implementation**

Add the same workflow language across all four instruction surfaces:

- start with `setup-autonomous`
- validate with `validate-autonomous-setup`
- use `plugins/qa/scripts/run-qa-tests.sh --quick` for QA quick mode

Extend the autonomous setup research doc with the self-configuration/operator-pack framing and references to the new execution layer.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/autonomous-setup-workflow.sh`
Expected: PASS with all docs aligned.

- [ ] **Step 5: Commit**

```bash
git add README.md .github/copilot-instructions.md .github/prompts/openclaw-autonomous-setup.prompt.md .github/instructions/openclaw-autonomy.instructions.md skills/openclaw-autonomous-setup/references/openclaw-setup-research.md
git commit -m "docs: align autonomous setup workflow entrypoints"
```

### Task 6: Final verification

**Files:**
- Test: `tests/autonomous-setup-workflow.sh`
- Test: `scripts/validate-autonomous-setup.sh`
- Test: `scripts/skill-lint.sh`
- Test: `plugins/qa/scripts/run-qa-tests.sh`

- [ ] **Step 1: Run the focused regression test**

Run: `bash tests/autonomous-setup-workflow.sh`
Expected: PASS

- [ ] **Step 2: Run the validator in normal mode**

Run: `bash scripts/validate-autonomous-setup.sh`
Expected: PASS summary plus successful lint of the three setup-related skills

- [ ] **Step 3: Run the QA quick mode**

Run: `bash plugins/qa/scripts/run-qa-tests.sh --quick`
Expected: PASS summary and generated report path

- [ ] **Step 4: Capture remaining risks**

Record any skipped runtime-only checks, especially where a live OpenClaw installation is not available.

- [ ] **Step 5: Commit**

```bash
git add plugins/qa/reports tests/autonomous-setup-workflow.sh
git commit -m "test: verify autonomous setup workflow integrity"
```
