# OpenClaw Autonomous Setup Research

This reference condenses the highest-signal findings from the local docs index `docs.openclaw.llms.txt`, official OpenClaw documentation, and the community repositories the user pointed to.

## What was analyzed

Official OpenClaw documentation areas reviewed:

- setup and onboarding
- gateway configuration and configuration reference
- automation and tasks
- multi-agent routing and sub-agents
- skills creation and skills loading
- ClawHub
- Telegram and Signal channels
- plugin packaging and bundle compatibility
- plugin setup metadata and ClawHub publishing

Community repositories reviewed:

- [theNetworkChuck/openclaw-setup](https://github.com/theNetworkChuck/openclaw-setup)
- [ishwarjha/openclaw-setup-guide-i-wish-i-had](https://github.com/ishwarjha/openclaw-setup-guide-i-wish-i-had)
- [czl9707/build-your-own-openclaw](https://github.com/czl9707/build-your-own-openclaw)
- [TechNickAI/openclaw-config](https://github.com/TechNickAI/openclaw-config)

## Official findings that matter most

### 1. Onboarding is the right default entrypoint

Official docs position `openclaw onboard` as the recommended setup path for macOS, Linux, and Windows via WSL2. It configures a local or remote gateway connection, channels, skills, and workspace defaults in one guided flow. This is the cleanest place for the agent to ask the operator all missing questions before applying config.

The current onboarding docs also make the operator-facing defaults explicit: QuickStart favors a local gateway on port `18789`, token auth, Control UI as the fastest first chat path, Tailscale off by default, and safe DM/channel defaults.

Operational implication:

- the setup skill should prefer `openclaw onboard` / `openclaw setup --wizard` on clean installs
- hand-editing `openclaw.json` should be incremental and only after discovery

### 2. Telegram is the fastest operator chat channel

Official Telegram docs describe the channel as production-ready, configured by `channels.telegram.botToken` or `tokenFile`, with `TELEGRAM_BOT_TOKEN` only as a fallback for the default account. Default DM policy is pairing, and multi-account setups should set an explicit default account to avoid routing ambiguity.

Operational implication:

- recommend Telegram first for chat-based control
- default to `dmPolicy: "pairing"` and mention-gated groups
- use explicit default account selection when multiple bots exist

### 3. Signal is viable but higher-friction

Official Signal docs define Signal as an external `signal-cli` integration over HTTP JSON-RPC + SSE. It requires `signal-cli` on the gateway host, recommends a separate bot number, and defaults to pairing-based DM access.

Operational implication:

- offer Signal only when privacy is a real requirement
- treat `signal-cli` install, registration, and daemon health as first-class validation items
- keep a fallback operator path such as WebChat or Telegram

### 4. Multi-agent control is explicit, not magical

Official configuration reference and Sub-Agents docs document `agents.defaults.subagents.allowAgents`, `maxSpawnDepth`, `maxChildrenPerAgent`, `maxConcurrent`, and `runTimeoutSeconds`. The same sources make clear that delegation should be allowlisted and nesting should stay bounded.

Operational implication:

- the plugin should drive users toward a master-plus-specialists topology with explicit `allowAgents`
- default to narrow delegation rights and small specialist workspaces

### 5. Automation is split into distinct mechanisms

Official automation docs separate:

- cron for precise schedules
- heartbeat for periodic awareness
- hooks for lifecycle-triggered automation
- standing orders for durable operating instructions
- task flow for multi-step orchestrations

Operational implication:

- the setup system should not dump all automation into cron
- the agent must choose the right automation surface based on intent

### 6. ClawHub is the native skills distribution path

Official docs say:

- `openclaw skills search/install/update` is the native workspace-focused skill flow
- `clawhub` CLI is only required for publish/sync/auth workflows
- workspace-installed skills take precedence over shared and bundled skills

Operational implication:

- the plugin should teach the agent to search/install skills via `openclaw skills ...` first
- a separate skill-publish workflow should be used only when the user wants registry sync or publishing

### 7. Skills are just folders, but they need discipline

Official skill docs confirm that a skill is a directory containing `SKILL.md` with YAML frontmatter and optional scripts/references. Metadata can gate by OS, required binaries, or config.

Operational implication:

- autonomous skill creation is realistic and should be part of the setup story
- new skills should be written as reusable bundles, not one-off prompt fragments

### 8. Existing Claude/Codex bundles should stay bundles

Official OpenClaw plugin docs distinguish native plugins from compatible bundles. The docs explicitly allow Claude/Codex/Cursor bundles to be installed directly and state that native plugin detection takes priority if both structures exist.

Operational implication:

- this repository should keep its bundle-first workflow
- add Codex and Copilot compatibility artifacts without forcing a native `openclaw.plugin.json` conversion

### 9. GitHub Copilot supports more than one repository instruction surface

Current GitHub documentation says Copilot can consume:

- repository-wide instructions in `.github/copilot-instructions.md`
- path-specific instructions in `.github/instructions/**/*.instructions.md`
- reusable prompt files in `.github/prompts/*.prompt.md`

Operational implication:

- this repository should ship a reusable setup prompt and path-specific instructions so Copilot can follow the same OpenClaw setup workflow as Claude Code and Codex

## Best-practice target architecture

Recommended baseline:

1. Install OpenClaw and complete onboarding.
2. Validate first reply through WebChat/Control UI.
3. Add Telegram as the main operator control surface.
4. Add Signal only if the operator explicitly values privacy enough to accept `signal-cli` overhead.
5. Create a master/orchestrator agent plus a small number of specialist agents:
   - research
   - coder
   - QA/verification
   - ops/integration
6. Install must-have skills from ClawHub into the active workspace.
7. Add heartbeat, cron, and standing orders only after the basic channel + provider path is healthy.
8. Run validation after every layer and repair failures immediately.

## Community repo takeaways

### theNetworkChuck/openclaw-setup

This repo is a concise one-pass walkthrough rather than a full operational manual. High-signal takeaways:

- use a real Linux/VPS host or another machine you can SSH into
- start with the official install one-liner, then let the wizard carry the first setup
- treat Telegram as the first practical remote control channel
- get to a working operator chat quickly, then iterate

High-signal takeaway:

- a setup plugin should have a fast path for first success before it branches into advanced hardening, memory, and multi-agent topology

### ishwarjha/openclaw-setup-guide-i-wish-i-had

This guide is valuable because it treats setup as an auditable end-to-end process rather than a single install command. High-signal takeaways:

- always inspect current state first
- use `openclaw doctor` early
- set up troubleshooting context before deep customization
- define primary model plus fallback
- treat identity, memory, heartbeat, and scheduled jobs as part of the real setup, not optional garnish

### czl9707/build-your-own-openclaw

This tutorial is valuable because it models OpenClaw capability growth in phases:

- single-agent capability first
- event-driven and channel support second
- multi-agent routing and autonomy third
- concurrency and memory last

High-signal takeaway:

- do not start with a giant multi-agent topology before the single-agent and channel foundations work

### TechNickAI/openclaw-config

This repository is valuable because it demonstrates a practical pattern:

- persistent memory
- many integration skills
- autonomous workflows that run on schedules

High-signal takeaway:

- the strongest real-world setups combine skills, memory, and recurring workflows, not just raw model access

## Recommended agent behavior during setup

The setup agent should:

1. ask grouped discovery questions before writes
2. inspect live state
3. propose the target architecture
4. apply config incrementally
5. validate each subsystem
6. repair failures before continuing
7. install skills from ClawHub when reuse is possible
8. create a new skill when reuse is not possible

## Configuration areas the setup agent must explicitly cover

- gateway mode and exposure
- provider auth and model fallback
- Control UI/WebChat first-run smoke test
- primary control channel
- DM and group security policy
- master/specialist agent topology
- sub-agent depth, allowlists, concurrency, and timeout limits
- skill installation and update strategy
- memory choice
- heartbeat/cron/hooks/standing orders strategy
- verification commands
- backup/recovery path

## Repository workflow integration

Inside this repository, the autonomous setup operator flow should be expressed through stable bundle entrypoints rather than scattered doc references.

Recommended route:

1. start with `setup-autonomous`
2. use `openclaw-autonomous-setup` for discovery and target-state design
3. use `openclaw-self-configurator` for the concrete rollout pack
4. validate repo integrity with `validate-autonomous-setup`
5. run `plugins/qa/scripts/run-qa-tests.sh --quick` for QA quick mode

This keeps the bundle honest: the workflow is only "autonomous" if its own docs, commands, skills, and QA runner agree on the same path.

## Source links

- [Onboarding (CLI)](https://docs.openclaw.ai/start/wizard)
- [CLI setup reference](https://docs.openclaw.ai/start/wizard-cli-reference)
- [Gateway configuration reference](https://docs.openclaw.ai/gateway/configuration-reference)
- [Automation and tasks](https://docs.openclaw.ai/automation/index)
- [Multi-agent routing](https://docs.openclaw.ai/concepts/multi-agent)
- [Sub-agents](https://docs.openclaw.ai/tools/subagents)
- [Creating skills](https://docs.openclaw.ai/tools/creating-skills)
- [ClawHub](https://docs.openclaw.ai/tools/clawhub)
- [Telegram](https://docs.openclaw.ai/channels/telegram)
- [Signal](https://docs.openclaw.ai/channels/signal)
- [Building plugins](https://docs.openclaw.ai/plugins/building-plugins)
- [Plugin bundles](https://docs.openclaw.ai/plugins/bundles)
- [Plugin setup and config](https://docs.openclaw.ai/plugins/sdk-setup)
- [About customizing GitHub Copilot responses](https://docs.github.com/en/copilot/concepts/prompting/response-customization)
- [theNetworkChuck/openclaw-setup](https://github.com/theNetworkChuck/openclaw-setup)
- [ishwarjha/openclaw-setup-guide-i-wish-i-had](https://github.com/ishwarjha/openclaw-setup-guide-i-wish-i-had)
- [czl9707/build-your-own-openclaw](https://github.com/czl9707/build-your-own-openclaw)
- [TechNickAI/openclaw-config](https://github.com/TechNickAI/openclaw-config)
