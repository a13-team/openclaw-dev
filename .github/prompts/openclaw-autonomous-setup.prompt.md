# OpenClaw Autonomous Setup

Turn this repository into the operator control pack for a real OpenClaw deployment.

## Required context

- [README.md](../../README.md)
- [AGENTS.md](../../AGENTS.md)
- [docs.openclaw.llms.txt](../../docs.openclaw.llms.txt)
- [skills/openclaw-autonomous-setup/SKILL.md](../../skills/openclaw-autonomous-setup/SKILL.md)
- [skills/openclaw-self-configurator/SKILL.md](../../skills/openclaw-self-configurator/SKILL.md)
- [skills/clawhub-skill-installer/SKILL.md](../../skills/clawhub-skill-installer/SKILL.md)
- [skills/openclaw-autonomous-setup/references/openclaw-setup-research.md](../../skills/openclaw-autonomous-setup/references/openclaw-setup-research.md)
- [skills/openclaw-autonomous-setup/references/openclaw-doc-map.md](../../skills/openclaw-autonomous-setup/references/openclaw-doc-map.md)
- [skills/openclaw-autonomous-setup/references/setup-target-state.md](../../skills/openclaw-autonomous-setup/references/setup-target-state.md)
- [skills/openclaw-autonomous-setup/references/setup-questionnaire.md](../../skills/openclaw-autonomous-setup/references/setup-questionnaire.md)

## Workflow

1. Inspect the existing repo and machine state before suggesting changes.
2. Enter through the repo workflow with `setup-autonomous`.
2. Ask grouped discovery questions before writing OpenClaw config if channels, providers, remote access, skill policy, or security boundaries are unclear.
3. Use official OpenClaw docs, not assumptions, to confirm onboarding, channel, sub-agent, and ClawHub behavior.
4. Design the target state first: control surfaces, providers, master/specialist topology, skills, memory, automation, and security.
5. Once the target state is approved, use `openclaw-self-configurator` to produce the concrete rollout pack.
6. Apply changes incrementally and verify each layer with focused checks such as `openclaw doctor`, `openclaw health`, `openclaw status --deep --all`, `openclaw channels status --probe`, and skill listing/eligibility checks.
7. If a required capability is missing, search and install it via `openclaw skills search/install`. If no suitable skill exists, create a new one.
8. Run `validate-autonomous-setup` and then `plugins/qa/scripts/run-qa-tests.sh --quick` before calling the workflow healthy.
9. If any step fails, analyze the exact error, repair the config or reinstall the skill/tool, and retry until the layer works or an external blocker remains.

## Desired outcome

Produce a system where OpenClaw can:

- be controlled from WebChat/Control UI and at least one chat channel
- run one master agent that delegates to specialist agents with explicit allowlists
- install skills from ClawHub by capability name
- validate and self-heal its own setup
- create a new reusable skill when no existing skill fits
