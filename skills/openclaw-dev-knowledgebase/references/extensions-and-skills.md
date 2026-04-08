# OpenClaw Extensions and Skills

<!-- Updated: 2026-04-08 -->

## Skills System

OpenClaw skills extend agent capabilities via modular packages. Each skill lives in a directory with a `SKILL.md` file.

### SKILL.md Format

```markdown
---
name: skill-name
description: "When to use this skill — specific trigger phrases and contexts"
metadata: {"clawdbot":{"always":false,"emoji":"🔧","requires":{"bins":["jq"]}}}
user-invocable: true
---

# Skill Title

Instructions for the agent...
```

### Skills Precedence Hierarchy (6 levels)

From highest to lowest priority:

| Level | Source | Path |
|-------|--------|------|
| 1 | Workspace skills | `<agent-workspace>/skills/<skill-name>/SKILL.md` |
| 2 | Per-agent skills | `~/.agents/skills/<skill-name>/SKILL.md` |
| 3 | User skills | `~/.openclaw/skills/<skill-name>/SKILL.md` |
| 4 | Bundled skills | `<openclaw-install>/skills/<skill-name>/SKILL.md` |
| 5 | Extra directories | `agents.defaults.skillsExtraDirs` |
| 6 | Bundled (lowest) | Built-in skills |

Higher precedence overrides lower. Workspace skills are per-agent.

### Per-Agent Skill Allowlists

```json
// ~/.openclaw/openclaw.json
{
  "agents": {
    "defaults": {
      "skills": ["skill-a", "skill-b"]  // Only these skills load
    },
    "list": [
      {
        "id": "my-agent",
        "skills": ["skill-c"]  // Additional skills for this agent
      }
    ]
  }
}
```

### Skill Gating

Skills can require conditions before loading:

```yaml
metadata:
  clawdbot:
    always: false          # Auto-inject into every session
    bins: ["jq", "git"]   # ALL must exist
    anyBins: ["python3", "python"]  # At least ONE must exist
    env: ["OPENAI_API_KEY"]  # ALL env vars must be set
    config: ["providers.openai"]  # Config path must exist
    os: ["darwin"]  # Only load on macOS
```

### Auto-Install Specs

Skills can declare auto-installation:

```yaml
metadata:
  clawdbot:
    install:
      - type: brew
        pkg: jq
      - type: npm
        pkg: typescript
      - type: download
        url: https://example.com/tool
        bins: ["tool"]
```

## Plugin Skills

Plugins can ship skills via manifest:

```json
// openclaw.plugin.json
{
  "id": "my-plugin",
  "skills": [
    {
      "name": "plugin-skill",
      "dir": "./skills/plugin-skill"
    }
  ]
}
```

## ClawHub

Find and install community skills from [ClawHub](https://clawhub.ai):

```bash
openclaw plugins install clawhub:<skill-name>
openclaw skills list --marketplace
```

## Security Notes

- **Dangerous-code scanner**: Scans skill files for hardcoded credentials, paths, API keys
- **Sandboxed runs**: Untrusted skills run in isolated environment
- **Environment injection**: Env vars scoped to agent run only
- **Session snapshot**: Skills loaded once per session for performance

## Bundled Skills (52)

| Skill | Description |
|-------|-------------|
| `1password` | 1Password integration |
| `apple-notes` | Apple Notes access |
| `apple-reminders` | Apple Reminders |
| `bear-notes` | Bear Notes |
| `blogwatcher` | Blog monitoring |
| `blucli` | Bluetooth CLI |
| `bluebubbles` | BlueBubbles iMessage |
| `camsnap` | Camera snapshot |
| `canvas` | Canvas / A2UI |
| `clawhub` | ClawHub integration |
| `coding-agent` | Coding agent capabilities |
| `discord` | Discord skill |
| `eightctl` | Eight Sleep control |
| `gemini` | Google Gemini |
| `gh-issues` | GitHub Issues |
| `gifgrep` | GIF search |
| `github` | GitHub integration |
| `gog` | GOG gaming |
| `goplaces` | Location/places |
| `healthcheck` | Health monitoring |
| `himalaya` | Email (Himalaya) |
| `imsg` | iMessage |
| `mcporter` | MCP bridge |
| `model-usage` | Model usage tracking |
| `nano-banana-pro` | Nano Banana Pro |
| `nano-pdf` | PDF processing |
| `notion` | Notion integration |
| `obsidian` | Obsidian notes |
| `openai-image-gen` | OpenAI image generation |
| `openai-whisper` | OpenAI Whisper (local) |
| `openai-whisper-api` | OpenAI Whisper (API) |
| `openhue` | Philips Hue control |
| `oracle` | Oracle skill |
| `ordercli` | Order management |
| `peekaboo` | Screen peek / capture |
| `sag` | Search and grep |
| `session-logs` | Session log analysis |
| `sherpa-onnx-tts` | Sherpa ONNX TTS |
| `skill-creator` | Skill creation helper |
| `slack` | Slack skill |
| `songsee` | Song recognition |
| `sonoscli` | Sonos control |
| `spotify-player` | Spotify control |
| `summarize` | Text summarization |
| `things-mac` | Things (macOS) |
| `tmux` | Tmux session control |
| `trello` | Trello integration |
| `video-frames` | Video frame extraction |
| `voice-call` | Voice calling |
| `wacli` | WhatsApp CLI |
| `weather` | Weather info |
| `xurl` | URL processing |

## Key Links

| Resource | URL |
|----------|-----|
| Docs | https://docs.openclaw.ai |
| Architecture | https://docs.openclaw.ai/concepts/architecture |
| Configuration | https://docs.openclaw.ai/gateway/configuration |
| Skills Docs | https://docs.openclaw.ai/tools/skills |
| Security | https://docs.openclaw.ai/gateway/security |
| Troubleshooting | https://docs.openclaw.ai/channels/troubleshooting |
| DeepWiki | https://deepwiki.com/openclaw/openclaw |
| Discord | https://discord.gg/clawd |
| ClawHub | https://clawhub.ai |
| MCP Bridge | https://github.com/steipete/mcporter |
