---
name: openclaw-autonomous-setup
description: "Use this skill when asked to fully set up, audit, harden, or evolve OpenClaw into an autonomous multi-agent system; when configuring Telegram, Signal, WebChat, remote control, providers, model fallbacks, memory, cron/heartbeat/hooks, ClawHub skill installation, or master-worker agent topologies; or when the user wants an agent that can ask the right setup questions, apply config changes, verify tools and channels, repair failed setup steps, and create missing skills autonomously."
metadata: {"clawdbot":{"always":false,"emoji":"🧭"}}
user-invocable: true
version: 1.1.0
---

# OpenClaw Autonomous Setup

Turn OpenClaw into a production-capable autonomous system without skipping discovery, safety, or verification.

> Non-negotiable:
> - Ask the operator the missing setup questions before writing config.
> - Use official docs plus the current machine state as ground truth.
> - Run `openclaw doctor` first whenever the environment already exists or anything breaks.
> - Verify after every meaningful change. Never declare setup complete without evidence.

Mandatory reference pack for this skill:

- `references/setup-questionnaire.md`
- `references/openclaw-setup-research.md`
- `references/openclaw-doc-map.md`
- `references/setup-target-state.md`
- `../openclaw-self-configurator/SKILL.md` when target-state design is complete and a concrete rollout pack must be produced
- `../clawhub-skill-installer/SKILL.md` when external skills are needed
- `../openclaw-skill-development/SKILL.md` when no existing skill fits

## Mission

Build or repair an OpenClaw deployment that can:

- operate through Telegram, Signal, WebChat, or a remote Gateway/control surface
- run one master agent with multiple specialist agents
- install and update skills from ClawHub with minimal operator effort
- validate channels, tools, providers, and automation loops after setup
- self-heal failed steps by analyzing errors and retrying with corrected config
- author a new skill when the required capability does not already exist

## Phase 0: Discovery Before Writes

If any of the sections below are unclear, stop and ask grouped questions first. Use the checklist in `references/setup-questionnaire.md`.

Required discovery groups:

1. Host and topology
   - Where will OpenClaw run: local machine, WSL2, VPS, Docker, or remote Gateway?
   - Is the target single-user or shared/multi-operator?
   - Is remote access needed over SSH, Tailscale, reverse proxy, or trusted local network only?

2. Control surfaces
   - Which entrypoints must work: WebChat/Control UI, Telegram, Signal, WhatsApp, Discord, or another channel?
   - Which channel is primary for the master agent?
   - Which channels are notification-only vs conversational?

3. Models and providers
   - Primary provider/model.
   - Fallback provider/model.
   - Whether coding-heavy work should route to Codex/OpenAI, Claude, Copilot, local models, or a gateway proxy.
   - Web search provider, voice/media needs, and budget/latency constraints.

4. Agent topology
   - What specialist agents are needed: research, coding, QA, ops, content, support, memory curator, etc.?
   - Which agent is the master/orchestrator?
   - Which agents may spawn or delegate to which others?
   - Whether nested delegation is required (`maxSpawnDepth: 2`) or if flat delegation is enough (`maxSpawnDepth: 1`).
   - Expected concurrency and timeout limits for sub-agent work.

5. Memory and automation
   - Is built-in memory enough, or should memory be backed by QMD/Honcho/another engine?
   - Which recurring behaviors are required: heartbeat, cron jobs, hooks, standing orders, task flow?
   - What data retention or backup expectations exist?

6. Security and secrets
   - Where will API keys and channel tokens live?
   - Should DM access default to pairing or allowlist?
   - Are group chats allowed, and if so, mention-gated or open?
   - Which steps the agent may apply automatically vs which ones require manual token paste, QR scan, or pairing approval.

7. Skill strategy
   - Which must-have skills should come from ClawHub?
   - Which repo-local skills already exist and should be reused?
   - Which missing capabilities should be authored as new skills?

## Phase 1: Baseline Inspection

Run the narrowest commands that establish the real state:

```bash
openclaw --version
openclaw doctor
openclaw health
openclaw status --deep --all
openclaw agents list --bindings
openclaw channels status --probe
openclaw skills list --verbose
openclaw plugins list
cat ~/.openclaw/openclaw.json
```

If OpenClaw is not installed yet, switch to installation flow first:

```bash
# macOS / Linux
curl -fsSL https://openclaw.ai/install.sh | bash

# Windows PowerShell
iwr -useb https://openclaw.ai/install.ps1 | iex
```

Prefer `openclaw onboard` or `openclaw setup --wizard` over hand-writing an initial config on a clean machine.

## Phase 2: Target-State Design

Use `references/openclaw-setup-research.md`, `references/openclaw-doc-map.md`, and `references/setup-target-state.md` to choose the architecture. Default to these opinions unless the user requires otherwise:

- Start with `openclaw onboard` because it configures workspace, providers, daemon, channels, and skills in one guided flow.
- Use WebChat/Control UI as the first smoke-test surface because it removes channel friction.
- Add Telegram next when a fast operator chat surface is needed.
- Add Signal only when privacy is a primary requirement and the operator accepts `signal-cli` complexity.
- Use pairing or allowlists by default for DMs and groups. Avoid `open` unless the trust boundary is explicit.
- Keep one master agent and a small set of specialists with narrow roles and dedicated workspaces.
- Keep sub-agent delegation allowlisted and explicit; only enable nested sub-agents when the master agent truly needs an orchestrator layer.
- Route difficult coding work to the strongest coding model/provider available; add fallbacks for general reasoning.

Document the target state before changing config:

- host/runtime
- gateway exposure model
- channels and access policy
- provider/model matrix
- agent list and delegation rules
- required skills/plugins
- automation plan
- validation checklist

When the target state is explicit, switch to `openclaw-self-configurator` to turn it into a concrete rollout pack before broad execution.

## Phase 3: Apply Configuration

Change config in small steps.

### 3.1 Providers and models

- Set the primary model.
- Add at least one fallback if uptime matters.
- Record budget-sensitive or latency-sensitive alternatives.
- Keep provider auth outside prompts and outside committed files.
- If web search, media, voice, or browser capabilities matter, configure those providers intentionally rather than assuming defaults.

### 3.2 Channels

Control UI / WebChat:

- Treat browser chat as the first smoke test because it removes channel setup friction.
- Only move to phone/chat channels after the base provider path works.

Telegram:

- Configure `channels.telegram.botToken` or `tokenFile`.
- Keep `dmPolicy: "pairing"` unless a stronger reason exists.
- Add `groups["*"].requireMention: true` for safer group rollout.
- In multi-account setups, set an explicit default account.

Signal:

- Ensure `signal-cli` is installed on the gateway host.
- Prefer a dedicated bot number.
- Configure `account`, `cliPath`, `dmPolicy`, and `allowFrom`.
- Approve pairings after first contact.

### 3.3 Agents and delegation

- Define the master agent and specialist agents in `agents.list`.
- Give agents dedicated workspaces when their skills or memories should differ.
- Configure sub-agent policy with an explicit allowlist.
- Keep `maxSpawnDepth: 1` unless the operator explicitly wants an orchestrator-with-workers pattern; then raise to `2` and set bounded `maxConcurrent` and `runTimeoutSeconds`.
- Keep roles narrow and observable.

### 3.4 Memory and automation

- Add heartbeat for periodic awareness tasks.
- Use cron for precise scheduled jobs.
- Use hooks for event-driven actions.
- Use standing orders for persistent operating rules.

### 3.5 Skills

First reuse local or bundled skills. Then install external skills only when needed:

```bash
openclaw skills search "<need>"
openclaw skills install <skill-slug>
openclaw skills update --all
```

Use the separate `clawhub` CLI only for publish/sync/auth workflows.
When the operator says only the capability name, use `clawhub-skill-installer` to search, install, validate, and repair the skill without making the user manually hunt for the slug.

## Phase 4: Validate Every Layer

After each setup batch, run checks that match the changed surface:

```bash
openclaw doctor
openclaw health
openclaw status --deep --all
openclaw channels status --probe
openclaw pairing list telegram
openclaw pairing list signal
openclaw skills list --eligible
openclaw tasks list
```

Validation expectations:

- Gateway is healthy.
- The configured provider can answer.
- The primary operator channel can receive and return a message.
- Pairing/allowlists behave as expected.
- Master agent can delegate only to approved specialists.
- Sub-agent depth, concurrency, and timeout behavior match the requested topology.
- Installed skills appear in the active workspace and trigger in a new session.
- Heartbeat/cron/hooks show evidence in logs or task history.
- Repo-level workflow integrity passes via `validate-autonomous-setup` and `plugins/qa/scripts/run-qa-tests.sh --quick`.

## Phase 5: Self-Healing Loop

If anything fails:

1. Capture the exact command, error, and relevant config fragment.
2. Run `openclaw doctor` again if the failure touches config, gateway, plugins, or channels.
3. Inspect the relevant subsystem:
   - `openclaw channels status --probe`
   - `openclaw plugins doctor`
   - `openclaw logs --follow`
   - provider-specific status or auth checks
4. Apply the smallest viable fix.
5. Re-run the failed step.
6. Do not move on until the layer is working or you hit a real external blocker.

Common repair actions:

- fix malformed JSON/JSON5 or wrong nesting
- resolve missing binaries (`signal-cli`, `node`, `jq`, etc.)
- reinstall or update a ClawHub skill
- correct DM/group policies and allowlists
- fix wrong account defaults in multi-account channels
- reduce sub-agent depth/concurrency if the orchestration design is too aggressive for the host
- restart the gateway after config changes

## Phase 6: Create Missing Skills

If no existing skill covers the task, create one instead of leaving the capability manual.

Minimum structure:

```text
skills/<skill-name>/
├── SKILL.md
├── scripts/      # optional
└── references/   # optional
```

Requirements:

- `SKILL.md` must include YAML frontmatter.
- The description must say what the skill does and when to use it.
- Put reusable logic into `scripts/` when plain markdown instructions are not enough.
- Use Python or JavaScript only when code genuinely improves repeatability.
- Validate the new skill with the existing repo tooling before treating it as installed.

Reuse `openclaw-skill-development` for the actual authoring workflow.

## Final Deliverable

End every run with a concise operator report:

- installed or changed components
- validated channels/providers/agents/skills
- validation route (`validate-autonomous-setup`, QA quick/full)
- remaining manual steps (for example, paste token, approve pairing, scan QR)
- residual risks or unsupported assumptions
- next recommended automation or skill to add

If the user asked for a full production setup, do not stop at documentation. Drive the work through configuration, validation, and repair until the system is genuinely usable.
