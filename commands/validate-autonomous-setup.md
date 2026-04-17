---
name: validate-autonomous-setup
description: "Validate that the repository's autonomous setup workflow is internally consistent across skills, commands, docs, and the QA runner."
user-invocable: true
---

# /validate-autonomous-setup — 校验 Autonomous Setup Workflow

Run the narrow bundle-integrity checks for the autonomous setup workflow.

## Execution

Preferred:

```bash
bash scripts/validate-autonomous-setup.sh
```

Windows fallback when `bash` is not on `PATH`:

```powershell
& 'C:\Program Files\Git\bin\bash.exe' scripts/validate-autonomous-setup.sh
```

## What it validates

- required command, skill, and reference files exist
- `setup-autonomous` and `validate-autonomous-setup` are documented consistently
- `openclaw-autonomous-setup` points to `openclaw-self-configurator`
- the canonical QA runner exists at `plugins/qa/scripts/run-qa-tests.sh`
- setup-related skills pass `scripts/skill-lint.sh`

## Follow-up

After a successful validation run, the next QA step is:

```bash
bash plugins/qa/scripts/run-qa-tests.sh --quick
```
