#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK_ONLY=0
FAILURES=0
WARNINGS=0

if [[ "${1:-}" == "--check-only" ]]; then
  CHECK_ONLY=1
fi

pass() {
  printf 'PASS %s\n' "$1"
}

warn() {
  printf 'WARN %s\n' "$1"
  WARNINGS=$((WARNINGS + 1))
}

fail() {
  printf 'FAIL %s\n' "$1"
  FAILURES=$((FAILURES + 1))
}

check_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    pass "file exists: ${path#$ROOT/}"
  else
    fail "missing file: ${path#$ROOT/}"
  fi
}

check_contains() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if grep -q "$pattern" "$path"; then
    pass "$label"
  else
    fail "$label"
  fi
}

required_files=(
  "$ROOT/commands/setup-autonomous.md"
  "$ROOT/commands/validate-autonomous-setup.md"
  "$ROOT/skills/openclaw-autonomous-setup/SKILL.md"
  "$ROOT/skills/openclaw-self-configurator/SKILL.md"
  "$ROOT/skills/openclaw-self-configurator/references/self-config-blueprint.md"
  "$ROOT/skills/openclaw-self-configurator/references/self-config-checklist.md"
  "$ROOT/skills/openclaw-self-configurator/references/recommended-skill-packs.md"
  "$ROOT/skills/clawhub-skill-installer/SKILL.md"
  "$ROOT/.github/copilot-instructions.md"
  "$ROOT/.github/prompts/openclaw-autonomous-setup.prompt.md"
  "$ROOT/.github/instructions/openclaw-autonomy.instructions.md"
  "$ROOT/plugins/qa/scripts/run-qa-tests.sh"
)

for path in "${required_files[@]}"; do
  check_file "$path"
done

check_contains "$ROOT/README.md" 'setup-autonomous' 'README mentions setup-autonomous'
check_contains "$ROOT/README.md" 'validate-autonomous-setup' 'README mentions validate-autonomous-setup'
check_contains "$ROOT/.github/copilot-instructions.md" 'setup-autonomous' 'Copilot instructions mention setup-autonomous'
check_contains "$ROOT/.github/copilot-instructions.md" 'validate-autonomous-setup' 'Copilot instructions mention validate-autonomous-setup'
check_contains "$ROOT/.github/prompts/openclaw-autonomous-setup.prompt.md" 'setup-autonomous' 'Prompt mentions setup-autonomous'
check_contains "$ROOT/.github/prompts/openclaw-autonomous-setup.prompt.md" 'validate-autonomous-setup' 'Prompt mentions validate-autonomous-setup'
check_contains "$ROOT/.github/instructions/openclaw-autonomy.instructions.md" 'setup-autonomous' 'Path instructions mention setup-autonomous'
check_contains "$ROOT/.github/instructions/openclaw-autonomy.instructions.md" 'validate-autonomous-setup' 'Path instructions mention validate-autonomous-setup'
check_contains "$ROOT/skills/openclaw-autonomous-setup/SKILL.md" 'openclaw-self-configurator' 'Autonomous setup skill references openclaw-self-configurator'
check_contains "$ROOT/plugins/qa/scripts/run-qa-tests.sh" 'validate-autonomous-setup.sh' 'QA runner calls validate-autonomous-setup.sh'

if [[ $CHECK_ONLY -eq 0 ]]; then
  for skill in \
    "$ROOT/skills/openclaw-autonomous-setup" \
    "$ROOT/skills/openclaw-self-configurator" \
    "$ROOT/skills/clawhub-skill-installer"
  do
    if bash "$ROOT/scripts/skill-lint.sh" "$skill"; then
      pass "skill lint passed: ${skill#$ROOT/}"
    else
      fail "skill lint failed: ${skill#$ROOT/}"
    fi
  done

  if [[ -x "$ROOT/plugins/qa/scripts/run-qa-tests.sh" ]]; then
    pass "QA runner is executable"
  else
    warn "QA runner is not marked executable; direct bash invocation still works"
  fi
fi

printf '\nSummary: %s failure(s), %s warning(s)\n' "$FAILURES" "$WARNINGS"

if [[ $FAILURES -gt 0 ]]; then
  exit 1
fi
