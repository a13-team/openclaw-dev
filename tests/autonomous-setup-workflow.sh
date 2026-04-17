#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

required_files=(
  "$ROOT/commands/setup-autonomous.md"
  "$ROOT/commands/validate-autonomous-setup.md"
  "$ROOT/skills/openclaw-self-configurator/SKILL.md"
  "$ROOT/skills/openclaw-self-configurator/references/self-config-blueprint.md"
  "$ROOT/skills/openclaw-self-configurator/references/self-config-checklist.md"
  "$ROOT/skills/openclaw-self-configurator/references/recommended-skill-packs.md"
  "$ROOT/scripts/validate-autonomous-setup.sh"
  "$ROOT/plugins/qa/scripts/run-qa-tests.sh"
)

for path in "${required_files[@]}"; do
  [[ -f "$path" ]] || {
    echo "MISSING: $path"
    exit 1
  }
done

grep -q 'setup-autonomous' "$ROOT/README.md" || {
  echo "README missing setup-autonomous"
  exit 1
}

grep -q 'validate-autonomous-setup' "$ROOT/README.md" || {
  echo "README missing validate-autonomous-setup"
  exit 1
}

for path in \
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

bash "$ROOT/scripts/validate-autonomous-setup.sh" --check-only
bash "$ROOT/plugins/qa/scripts/run-qa-tests.sh" --quick >/dev/null
