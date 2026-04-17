# openclaw-dev

**Give your Code Agent full OpenClaw full-stack development and autonomous setup capabilities.**

An OpenClaw development toolkit for AI code agents. Works as a Claude Code plugin by default, as a Codex-compatible bundle, and as a GitHub Copilot-guided workspace. It can also be installed into OpenClaw as a Claude-compatible bundle on other platforms.

## Quick Install

### Claude Code (Recommended)

```bash
git clone https://github.com/a13-team/openclaw-dev.git
# Enable plugin in Claude Code (point to the cloned directory)
```

The plugin auto-registers — no manual configuration needed.

### OpenClaw

```bash
git clone https://github.com/a13-team/openclaw-dev.git
cd openclaw-dev
openclaw plugins install .
openclaw plugins inspect openclaw-dev
```

OpenClaw recognizes this repo as a Claude-compatible bundle. Currently reliably mapped: `skills/`, `commands/` and other bundle capabilities. `agents/` remains detect-only and should not be used as an OpenClaw native agent plugin.

### Codex / Qwen / Gemini

```bash
cd openclaw-dev && bash install.sh
```

Auto-detects installed agents and distributes to each platform's convention directory. On Windows, prefer `.\install.ps1`.

### GitHub Copilot

Use the repository as-is. Copilot reads the repo-level instruction file at `.github/copilot-instructions.md`, which points it to the OpenClaw setup workflow, docs index, and bundle compatibility rules.

**Update (clean refresh):**
- Unix-like: `cd openclaw-dev && git pull && bash install.sh`
- Windows PowerShell: `cd openclaw-dev; git pull; .\install.ps1`

> The installer uses **Manifest Sync** — automatically tracks installed skills and commands.
> When you delete a skill and re-run `install.sh`, old versions are precisely cleaned from target directories, leaving no ghost files.
> User-created skills in the target directory are not affected.

## After Installation

Use natural language or `/commands` directly in your code agent:

```
帮我安装 OpenClaw              → Auto-execute install, onboard, Gateway config
OpenClaw 架构原理              → Read architecture docs and internals
创建一个 skill                 → Complete lifecycle: requirements → design → implement → validate → deploy
```

## Autonomous OpenClaw Setup

This repo now includes an explicit autonomous setup playbook for turning OpenClaw into a managed multi-agent system.

- Primary command: `/setup-autonomous`
- Integrity check: `/validate-autonomous-setup`
- Main skill: `skills/openclaw-autonomous-setup`
- Execution skill: `skills/openclaw-self-configurator`
- ClawHub install skill: `skills/clawhub-skill-installer`
- Research reference: `skills/openclaw-autonomous-setup/references/openclaw-setup-research.md`
- Official docs map: `skills/openclaw-autonomous-setup/references/openclaw-doc-map.md`
- Target-state blueprint: `skills/openclaw-autonomous-setup/references/setup-target-state.md`
- Setup questionnaire: `skills/openclaw-autonomous-setup/references/setup-questionnaire.md`
- GitHub Copilot prompt: `.github/prompts/openclaw-autonomous-setup.prompt.md`

Suggested repo workflow:

```text
/setup-autonomous
/validate-autonomous-setup
bash plugins/qa/scripts/run-qa-tests.sh --quick
```

Target outcome:

- one master agent orchestrating specialist agents
- operator control through Telegram, Signal, or Control UI/WebChat
- ClawHub-powered skill installation and updates
- self-configuration rollout packs grounded in approved target state
- validation and self-healing after each setup step
- autonomous skill creation when no existing skill fits
- reusable guidance for Claude Code, Codex, and GitHub Copilot in the same workspace

## Use Cases

### Install & Deploy

```
帮我在这台 Linux 服务器上安装 OpenClaw，配置 Gateway 和 Tailscale
```

Cross-platform install (macOS / Linux / Windows WSL2), includes onboard, Gateway service, and networking.

### Diagnosis & Fix

```
/diagnose
OpenClaw Gateway 频繁重启，帮我诊断
```

Systematic log analysis → match known fault patterns → locate root cause → provide fix steps. Each new pattern found automatically沉淀, **improves over time**.

### Status Query

```
/status
/status home-mac
/status ALL
```

Unified status view of Gateway, Agents, Channels, Plugins. Supports parallel multi-Gateway queries.

### Config Check

```
/lint-config
```

Validates `openclaw.json` syntax, required fields, security settings, and path accessibility. Prevents config errors that break the Agent.

### Skill Development

```
帮我给 momiji agent 创建一个语音播报技能
/create-skill
/deploy-skill
/validate-skill
```

Full Skill development lifecycle: requirements → design → implement → validate → deploy.

### Skill Evolution

```
/evolve-skill momiji voice-engine
```

Analyzes session logs, finds skill trigger rate, error rate, improvement directions — data-driven optimization.

### Fleet Real-Time Monitoring

```
/watch
/status ALL
```

Persistent tmux split-panel monitoring dashboard, real-time remote node status. Opens and stays active, all remote operations visualized.

## All Commands

| Command | Purpose |
|---------|---------|
| `/diagnose` | Runtime log diagnosis |
| `/status` | Status overview (multi-Gateway) |
| `/lint-config` | Config validation |
| `/setup-node` | Node install & deploy |
| `/qa-agent` | QA diagnosis & fix (`--fix` enables fix loop) |
| `/evolve-skill` | Data-driven skill evolution |
| `/create-skill` | New skill creation |
| `/deploy-skill` | Skill deployment |
| `/validate-skill` | Skill validation |
| `/list-skills` | List all skills |
| `/scaffold-agent` | Agent scaffolding |
| `/plugin` | Plugin full lifecycle (create/install/uninstall/update/enable/disable/diagnose) |
| `/watch` | Fleet real-time monitoring dashboard |

## Cross-OS Support

| Platform | OpenClaw Install |
|----------|-----------------|
| macOS | `curl -fsSL https://openclaw.ai/install.sh \| bash` |
| Linux | `curl -fsSL https://openclaw.ai/install.sh \| bash` |
| Windows | WSL2 + `iwr -useb https://openclaw.ai/install.ps1 \| iex` |

## This Repo's Install Targets

| Target | Recommended Command |
|--------|-------------------|
| Claude Code | Clone and enable in Claude Code |
| OpenClaw | `openclaw plugins install .` |
| Windows local distribution | `.\install.ps1` |
| macOS / Linux / WSL distribution | `bash install.sh` |

## Local Config (Optional)

Copy `openclaw-dev.local.md.example` to `.claude/openclaw-dev.local.md` to customize:

- Multi-Gateway connection info (`gateways:` config)
- Workspace paths
- Deploy directories

## Changelog

### v2.2.0 (2026-03-09)

**Install Refactor — Clean Refresh (Manifest Sync):**
- `install.sh` changed to manifest-driven sync, writes `.openclaw-dev.manifest` to target directory after each install
- Re-runs auto-compare manifest, precisely removes skills/commands removed from repo (zero ghost files)
- User-created skills not in manifest range, never accidentally deleted
- Idempotent: however many runs, target directory always matches repo exactly

### v2.1.0 (2026-03-04)

**Command Refactor** — clearer naming:

**Skill Optimization:**
- `openclaw-node-operations`: status query rewritten as tiered execution (env detection → normal/degraded mode), weak models can also complete quickly
- New degraded strategy table — auto-fallback to config file when openclaw CLI unavailable

**Tool Enhancement:**
- `skill-lint.sh` new outdated command reference detection

### v2.0.0

- First release as Claude Code plugin
- 4 orthogonal Skills + 13 user commands
- Cross-platform distribution (Codex / Qwen / Gemini)
- Closed-loop diagnosis (fault-patterns.md auto-沉淀)

## License

MIT
