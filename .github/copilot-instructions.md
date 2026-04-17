# OpenClaw Dev for GitHub Copilot

This repository is a cross-agent OpenClaw toolkit. Treat it as a compatible bundle for Claude Code and Codex, plus a Copilot-guided workspace for OpenClaw development and operations.

## Primary goal

Help the user install, configure, validate, and evolve OpenClaw into a production-capable autonomous system with:

- one master agent and multiple specialist agents
- explicit model/provider routing and fallback choices
- chat control via Telegram, Signal, or browser/control UI
- ClawHub-based skill discovery and installation
- self-healing validation loops after every meaningful change
- autonomous skill authoring when an existing skill does not cover the need

## Repository anchors

- Read [README.md](../README.md) first for install targets and repo purpose.
- Read [AGENTS.md](../AGENTS.md) for Codex-facing workspace rules.
- Use [docs.openclaw.llms.txt](../docs.openclaw.llms.txt) as the local index of official OpenClaw docs.
- For the autonomous setup workflow, use [skills/openclaw-autonomous-setup/SKILL.md](../skills/openclaw-autonomous-setup/SKILL.md).
- After target-state design, use [skills/openclaw-self-configurator/SKILL.md](../skills/openclaw-self-configurator/SKILL.md).
- For ClawHub skill discovery/install/update flows, use [skills/clawhub-skill-installer/SKILL.md](../skills/clawhub-skill-installer/SKILL.md).
- For final architecture and doc coverage, use [skills/openclaw-autonomous-setup/references/setup-target-state.md](../skills/openclaw-autonomous-setup/references/setup-target-state.md) and [skills/openclaw-autonomous-setup/references/openclaw-doc-map.md](../skills/openclaw-autonomous-setup/references/openclaw-doc-map.md).
- For plugin/bundle compatibility, preserve `.claude-plugin/` and `.codex-plugin/` structures.
- When using GitHub Copilot Chat in VS Code or JetBrains, prefer the reusable prompt at [.github/prompts/openclaw-autonomous-setup.prompt.md](./prompts/openclaw-autonomous-setup.prompt.md).
- Start the repo workflow with `setup-autonomous` and close the repo-integrity loop with `validate-autonomous-setup`.

## Operating rules

1. Inspect before editing. Prefer exact file reads and targeted changes.
2. Ask grouped discovery questions before writing OpenClaw configuration if operator intent, channels, models, security boundaries, or credentials are unclear.
3. Prefer official OpenClaw docs and current config state over assumptions.
4. Run `openclaw doctor` first when troubleshooting.
5. After each configuration step, verify with focused checks such as `openclaw health`, `openclaw status --deep`, `openclaw channels status --probe`, `openclaw skills list`, and `openclaw pairing list`.
6. Validate bundle integrity with `validate-autonomous-setup`, then use `plugins/qa/scripts/run-qa-tests.sh --quick` before claiming the workflow is healthy.
7. If a setup step fails, analyze the exact error, repair config or reinstall the skill/tool, and retry until the system is working or a hard external blocker remains.
8. Never hardcode secrets, personal tokens, or machine-specific paths into committed files.
9. Prefer bundle-compatible changes unless a native `openclaw.plugin.json` is explicitly requested.
10. Treat `docs.openclaw.llms.txt` as an index, not the source of truth itself. Follow the linked official docs pages for the final rule.

## OpenClaw-specific expectations

- Telegram is usually the fastest chat channel to stand up; Signal is more privacy-oriented but depends on `signal-cli`.
- Use pairing and allowlists by default instead of open inbound access.
- Separate master and specialist agents by workspace, role, and skill loadout.
- Use ClawHub through `openclaw skills search/install/update` for native workspace installs; use the separate `clawhub` CLI only when publish/sync/auth flows are actually needed.
- If a missing capability blocks progress, create a new skill as `skills/<skill-name>/SKILL.md` with YAML frontmatter plus supporting `scripts/` or `references/` only when needed.
- For orchestrator topologies, keep sub-agent allowlists explicit and only raise nesting depth when the main agent truly needs worker-of-worker delegation.
