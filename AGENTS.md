# OpenClaw Dev (Codex Adapter)

OpenClaw / Claude plugin development toolkit. Codex entry point.

## Directory Structure

| Path | Purpose |
|------|---------|
| `commands/` | Claude-style command templates (process reference) |
| `agents/` | Agent templates with validation rules |
| `skills/` | OpenClaw skill development references and scripts |
| `scripts/` | General validation scripts |
| `plugins/qa/` | QA diagnosis framework (diagnosis and evolution execution layer) |

## Common Workflows

```bash
# 1. Diagnose OpenClaw capabilities
bash plugins/qa/scripts/run-qa-tests.sh --agent <agent-id> --quick
bash plugins/qa/scripts/run-qa-tests.sh --agent <agent-id> --full

# 2. Validate skill definition quality
bash scripts/skill-lint.sh skills/<skill-name>

# 3. Verify skill is loaded in agent session
bash skills/openclaw-skill-development/scripts/verify-skill-loaded.sh <agent-id> <skill-name>

# 4. Contextual model routing
oc-route --list-presets
oc-route sensitive-research -m "..." --pretty
# Fallback: python3 scripts/oc-route.py ...
```

Reports output to: `plugins/qa/reports/`

## Evolution Sequence

1. `plugins/qa` quick diagnosis → locate failure scenarios
2. Modify `skills/` / agent config / OpenClaw environment
3. `scripts/skill-lint.sh` static validation
4. Re-run `plugins/qa` to verify regression
5. Fix strategies沉淀 to `skills/` / `commands/` / `agents/`

## Compatibility Notes

- `.claude-plugin/plugin.json` is the OpenClaw plugin manifest — do not rename
- Claude-specific instructions in `commands/*.md` (like `AskUserQuestion`) are process templates, not directly executed
- Path overrides: `plugins/qa/scripts/run-qa-tests.sh` supports environment variable overrides
