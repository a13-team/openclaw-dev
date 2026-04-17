# OpenClaw Setup Docs Map

This file turns the `docs.openclaw.llms.txt` index into a setup-oriented reading map. Use it when the agent needs to verify a decision against the official docs rather than relying on memory.

## Foundation

| Doc | Why it matters |
|-----|----------------|
| [Onboarding (CLI)](https://docs.openclaw.ai/start/wizard) | Recommended first-run flow, QuickStart vs Advanced, default gateway/channel behavior. |
| [Configuration](https://docs.openclaw.ai/gateway/configuration) | High-level overview of how `~/.openclaw/openclaw.json` works. |
| [Configuration Reference](https://docs.openclaw.ai/gateway/configuration-reference) | Exact config surface for channels, agents, tools, secrets, automation, and sub-agents. |
| [Doctor](https://docs.openclaw.ai/gateway/doctor) | First diagnostic ladder when setup or config breaks. |
| [Troubleshooting](https://docs.openclaw.ai/gateway/troubleshooting) | Gateway and runtime repair paths. |

## Channels and operator control

| Doc | Why it matters |
|-----|----------------|
| [Telegram](https://docs.openclaw.ai/channels/telegram) | Bot token, token file, DM policies, multi-account behavior, group mention gating. |
| [Signal](https://docs.openclaw.ai/channels/signal) | `signal-cli` requirements, pairing, allowlists, and troubleshooting. |
| [Pairing](https://docs.openclaw.ai/channels/pairing) | Approval flow for safer inbound DM rollout. |
| [Channel Routing](https://docs.openclaw.ai/channels/channel-routing) | Multi-channel and channel-specific routing decisions. |
| [Dashboard](https://docs.openclaw.ai/cli/dashboard.md) | Fastest smoke-test route after onboarding. |
| [WebChat (macOS)](https://docs.openclaw.ai/platforms/mac/webchat.md) | Browser-first control surface reference when the operator starts from a desktop host. |

## Multi-agent topology

| Doc | Why it matters |
|-----|----------------|
| [Multi-Agent Routing](https://docs.openclaw.ai/concepts/multi-agent) | High-level architecture for splitting work across agents. |
| [Sub-Agents](https://docs.openclaw.ai/tools/subagents) | `allowAgents`, `maxSpawnDepth`, `maxConcurrent`, `runTimeoutSeconds`, and announce behavior. |
| [Agent Runtime](https://docs.openclaw.ai/concepts/agent) | What an agent is, what a workspace owns, and runtime boundaries. |
| [Agent Workspace](https://docs.openclaw.ai/concepts/agent-workspace) | Why specialist agents should often have separate workspaces. |

## Skills and extensibility

| Doc | Why it matters |
|-----|----------------|
| [Creating Skills](https://docs.openclaw.ai/tools/creating-skills) | Required `SKILL.md` structure and authoring expectations. |
| [ClawHub](https://docs.openclaw.ai/tools/clawhub) | Native registry/search/install/update/publish workflows. |
| [Skills (macOS)](https://docs.openclaw.ai/platforms/mac/skills.md) | Notes about skill loading on desktop hosts. |

## Automation and autonomy

| Doc | Why it matters |
|-----|----------------|
| [Automation & Tasks](https://docs.openclaw.ai/automation/index) | Overview of cron, hooks, standing orders, and task flow. |
| [Scheduled Tasks](https://docs.openclaw.ai/automation/cron-jobs) | Precise recurring work. |
| [Hooks](https://docs.openclaw.ai/automation/hooks) | Event-driven triggers. |
| [Standing Orders](https://docs.openclaw.ai/automation/standing-orders) | Long-lived operating instructions. |
| [Task Flow](https://docs.openclaw.ai/automation/taskflow) | Multi-step orchestration. |

## Security and remote operations

| Doc | Why it matters |
|-----|----------------|
| [Authentication](https://docs.openclaw.ai/gateway/authentication) | Gateway access control design. |
| [Secrets Management](https://docs.openclaw.ai/gateway/secrets) | Keeping tokens out of prompts and committed files. |
| [Sandbox vs Tool Policy vs Elevated](https://docs.openclaw.ai/gateway/sandbox-vs-tool-policy-vs-elevated) | Tool safety and trust boundary decisions. |
| [Remote Gateway Setup](https://docs.openclaw.ai/gateway/remote-gateway-readme) | When the operator wants remote control on another host. |
| [Tailscale](https://docs.openclaw.ai/gateway/tailscale) | Safe remote access pattern for personal deployments. |

## Bundle compatibility

| Doc | Why it matters |
|-----|----------------|
| [Plugin Bundles](https://docs.openclaw.ai/plugins/bundles) | Why this repo should stay a Claude/Codex bundle rather than being force-converted into a native plugin. |
| [Building Plugins](https://docs.openclaw.ai/plugins/building-plugins) | Native plugin path, only when a bundle is not enough. |
| [Plugin Setup and Config](https://docs.openclaw.ai/plugins/sdk-setup) | Native setup/config surfaces if the user explicitly asks for them. |
| [Codex Harness](https://docs.openclaw.ai/plugins/codex-harness) | How OpenClaw can route turns through the Codex app-server path when relevant. |

## Rule of use

When a decision touches one of the areas above, open the corresponding official page before changing config. Treat this map as a routing aid, not as a substitute for the underlying docs.
