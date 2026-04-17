---
applyTo: "README.md,skills/**/*.md,commands/**/*.md,agents/**/*.md,.claude-plugin/plugin.json,.codex-plugin/plugin.json"
---

- Treat this repository as a bundle-first OpenClaw plugin; preserve `.claude-plugin/` and `.codex-plugin/` and do not force-convert it into a native `openclaw.plugin.json` plugin unless the user explicitly asks.
- For autonomous setup content, require grouped discovery questions, incremental config changes, validation after each meaningful step, and a self-healing retry loop.
- Use the official OpenClaw docs linked from `docs.openclaw.llms.txt` as the source of truth for onboarding, channels, sub-agents, ClawHub, and bundle compatibility.
- Keep WebChat/Control UI as the first smoke-test surface, Telegram as the default fast operator channel, and Signal as an optional high-friction privacy channel.
- When a capability is missing, prefer a reusable skill under `skills/<skill-name>/SKILL.md` with YAML frontmatter and only minimal `scripts/` or `references/`.
- Enter the repo workflow with `setup-autonomous`, use `openclaw-self-configurator` after target-state design, and close the loop with `validate-autonomous-setup` plus `plugins/qa/scripts/run-qa-tests.sh --quick`.
