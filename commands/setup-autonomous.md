---
name: setup-autonomous
description: "Drive the full OpenClaw autonomous setup workflow: discovery, target-state design, self-configuration rollout pack, validation, and QA handoff."
argument-hint: [--repair] [scope]
user-invocable: true
---

# /setup-autonomous — 完整 Autonomous Setup Workflow

Use this command when the user wants a full autonomous OpenClaw setup flow rather than a single install or isolated config tweak.

## Workflow

1. Inspect the current repo and machine state.
2. Use `skills/openclaw-autonomous-setup` for discovery and target-state design.
3. Once the target state is explicit, switch to `skills/openclaw-self-configurator` to produce the rollout pack:
   - topology blueprint
   - config skeleton guidance
   - skill install plan
   - validation matrix
   - repair playbook
4. When external capabilities are needed, use `skills/clawhub-skill-installer`.
5. Finish with:
   - `/validate-autonomous-setup`
   - `plugins/qa/scripts/run-qa-tests.sh --quick`

## Mode Notes

- Default: design plus rollout-pack generation
- `--repair`: focus on broken wiring, drift, or validation failures in an existing autonomous setup workflow

## Output

Always return:

- approved target state
- rollout pack
- validation route
- remaining manual/operator steps
