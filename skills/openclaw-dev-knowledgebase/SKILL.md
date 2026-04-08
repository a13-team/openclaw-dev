---
name: openclaw-dev-knowledgebase
description: "Use this skill when the user asks about OpenClaw architecture overview, how OpenClaw works internally, session model, channel concepts, workspace structure, agent routing internals, plugin API design (openclaw.plugin.json, api.register*), agent configuration schema (agents.list[], bindings), multi-agent delegation model, SOUL.md/AGENTS.md/USER.md persona design, memory search internals, cron/heartbeat mechanisms, hooks/webhooks architecture, browser automation model, tool policy design, sandbox security model, node pairing protocol, discovery protocol, CLI command reference, source code structure, building from source, testing, releasing, or any OpenClaw internals/theory question. Also use for: 'create an agent', 'scaffold agent', 'create a plugin', 'scaffold plugin', 'sync knowledge', 'update knowledge base'. For hands-on operations (install, debug, configure, fix, diagnose, set up networking) use openclaw-node-operations instead."
metadata: {"clawdbot":{"always":false,"emoji":"📚","requires":{"bins":["jq"]}}}
user-invocable: true
version: 4.0.0
---

# OpenClaw Dev Knowledgebase

Comprehensive OpenClaw knowledge base — features/architecture/development/deployment/operations + plugin API + agent configuration.

> ⛔ **Iron Law: Never破坏 Memory**
> - Absolutely never delete, overwrite, or truncate any files in `memory/` directory or `MEMORY.md`
> - Only **append** operations allowed, no rewrite or truncate
> - When migrating workspaces, must completely preserve `memory/` and `MEMORY.md`
>
> ⛔ **Iron Law: Run `openclaw doctor` First**
> - Any anomaly, run `openclaw doctor` first — it auto-detects and fixes common issues
>
> ⛔ **Iron Law: Zero Hardcoding (Org Rule #1)**
> - Skill files forbidden to hardcode: paths (`/Users/`, `/Volumes/`), emails, IP:Port, API Key, model names
> - Runtime value authoritative sources: `~/.openclaw/openclaw.env` (env vars), `~/.openclaw/openclaw.json` (config)
> - Lab paths (`/Volumes/EXT/openclaw-god/`) forbidden in any production-side workspace files

## Knowledge Index

### Core Concepts

| Topic | Reference |
|-------|-----------|
| Node / Workspace / Agent / Model | `references/core-concepts.md` |
| Sessions / Memory / Automation / Security | `references/sessions-memory-automation-security.md` |
| Hooks / Webhooks / Heartbeat | `references/hooks-webhooks-heartbeat.md` |
| Tools / Browser / Plugins | `references/tools-browser-plugins.md` |
| Workspace / Channels / Discovery | `references/workspace-channels-discovery.md` |

### Development Guide

| Topic | Reference |
|-------|-----------|
| **Plugin API** (openclaw.plugin.json, api.register*) | `references/plugin-api.md` |
| Plugin Examples and Troubleshooting | `references/plugin-examples.md` |
| **Agent Configuration** (agents.list[], bindings, security) | `references/agent-config.md` |
| System Prompt Examples (SOUL.md, AGENTS.md, USER.md) | `references/system-prompt-examples.md` |

### Operations Reference

| Topic | Reference |
|-------|-----------|
| Install and Debug (macOS/Linux/Windows) | `references/install-and-debug.md` |
| Multi-node Networking (Tailscale, SSH, Remote Node) | `references/multi-node-networking.md` |
| Network Model | `references/networking.md` |
| Runbooks | `references/runbooks.md` |

### Runtime Analysis (Living Docs)

| Topic | Reference |
|-------|-----------|
| **Log Analysis Methodology** (5-step systematic analysis) | `references/log-analysis-methodology.md` |
| **Fault Patterns Library** (known pattern signatures, agent can append) | `references/fault-patterns.md` |

### Source Code Reference

| Topic | Reference |
|-------|-----------|
| Source Code Directory Structure | `references/source-code-map.md` |
| Extensions and Skills | `references/extensions-and-skills.md` |

### Operation Guides (Runbooks)

| Operation | Reference |
|-----------|-----------|
| **Create New Agent** (interactive scaffold) | `references/scaffold-agent-guide.md` |
| **Create New Plugin** (interactive scaffold) | `references/scaffold-plugin-guide.md` |
| **Plugin Operations Management** (install/uninstall/upgrade/diagnosis) | `references/plugin-management.md` |
| **Sync Knowledge Base** (align with upstream docs) | `references/sync-knowledge-runbook.md` |

## Core Architecture

```
Gateway (control plane, single process)
├── Agents (multiple, each with independent workspace/sessions)
├── Channels (WhatsApp, Telegram, Discord, iMessage...)
├── Plugins (TypeScript extensions: tools/channels/providers)
├── Nodes (paired devices: exec/screen/canvas/camera)
└── Sessions (DM isolation, one session per conversation)
```

## Key Paths

| Path | Description |
|------|-------------|
| `~/.openclaw/openclaw.json` | Main config |
| `~/.openclaw/agents/<id>/sessions/` | Session logs |
| `~/.openclaw/workspace-<id>/` | Agent workspace |
| `~/.openclaw/extensions/` | Global plugin directory |

## Common Commands

```bash
# Status
openclaw health
openclaw status --deep --all
openclaw doctor

# Agents
openclaw agents list --bindings
jq '.agents.list[] | {id, model, workspace}' ~/.openclaw/openclaw.json

# Channels
openclaw channels status --probe

# Plugins
openclaw plugins list

# Gateway Management
openclaw gateway install
openclaw gateway start | stop | restart
```

## Installation

| Platform | Command |
|----------|---------|
| macOS / Linux | `curl -fsSL https://openclaw.ai/install.sh \| bash` |
| Windows (WSL2) | `iwr -useb https://openclaw.ai/install.ps1 \| iex` |
| No root | `curl -fsSL https://openclaw.ai/install-cli.sh \| bash` |

## Plugin Development Quick Start

```bash
# 1. Create directory + manifest + package.json
mkdir my-plugin && cd my-plugin
cat > openclaw.plugin.json << 'EOF'
{"id": "my-plugin", "name": "My Plugin", "description": "What it does", "configSchema": {"type": "object", "additionalProperties": false, "properties": {}}}
EOF
cat > package.json << 'EOF'
{"name": "my-plugin", "version": "1.0.0", "type": "module", "openclaw": {"extensions": ["./index.ts"]}}
EOF

# 2. TypeScript entry (must be in root, not in src/)
cat > index.ts << 'EOF'
import { Type } from "@sinclair/typebox";
import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

export default definePluginEntry({
  id: "my-plugin",
  name: "My Plugin",
  description: "What it does",
  register(api) {
    api.registerTool({
      name: "my_tool",
      description: "My tool",
      parameters: Type.Object({ input: Type.String() }),
      async execute(_toolCallId, params) {
        return { content: [{ type: "text", text: params.input }] };
      },
    });
  },
});
EOF

# 3. Link install (dev mode)
openclaw plugins install -l .
```

## Agent Configuration Quick Start

```json5
// ~/.openclaw/openclaw.json → agents.list[]
{
  id: "my-agent",
  name: "My Agent",
  workspace: "~/.openclaw/workspace-my-agent",
  model: "anthropic/claude-sonnet-4-5",
  subagents: { allowAgents: ["worker-1"] },
}
```

Workspace bootstrap files: `SOUL.md` (identity) / `AGENTS.md` (delegation) / `USER.md` (user preferences)

## Skill Resolution Order

```
Workspace skills  (highest priority)
  └── ~/.openclaw/workspace-<agent>/skills/
Managed skills    (medium)
  └── ~/.openclaw/skills/ (shared)
Bundled skills    (lowest)
  └── Built into OpenClaw
```
