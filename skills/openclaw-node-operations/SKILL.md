---
name: openclaw-node-operations
description: "Use this skill when asked to install OpenClaw, set up a node, configure a Gateway, onboard a new machine, debug OpenClaw issues (read logs, run doctor, health checks, diagnose faults), fix Gateway problems, set up networking (Tailscale, SSH tunnels), check node status, troubleshoot connectivity, configure remote access, deploy on Linux/Windows/macOS, lint config, validate openclaw.json, check fleet status, query agent/channel/plugin status, or run systematic diagnostics. Also use for: 'diagnose OpenClaw', 'lint my config', 'validate configuration', 'show status', 'fleet status', 'Gateway health', 'check OpenClaw health'. Covers hands-on operations: installation, onboarding, Gateway service management, remote access, cross-OS support, debugging, monitoring, diagnostics, config validation. For architecture/theory questions use openclaw-dev-knowledgebase instead."
metadata: {"clawdbot":{"always":false,"emoji":"🖥️","requires":{"bins":["jq","ssh"]}}}
user-invocable: true
version: 3.0.0
---

# OpenClaw Node Operations

Install, configure, debug, network, monitor, and diagnose nodes.

> ⛔ **Iron Law: Never Destroy Memory**
> - Never delete, overwrite, or truncate any files in `memory/` directory or `MEMORY.md`
> - Only **append** operations allowed, no rewrite or truncate
> - When migrating workspaces, must completely preserve `memory/` and `MEMORY.md`
> - Any `rm -rf`, `rsync --delete` involving workspace directory must exclude `memory/`
>
> ⛔ **Iron Law: Run `openclaw doctor` First**
> - Any anomaly (Gateway won't start, Agent not responding, Skill not loading, Channel disconnected) run `openclaw doctor` first
> - doctor auto-detects and fixes common issues — read output before deciding next step

## Installation

### Quick Install (Recommended)

| Platform | Command |
|----------|---------|
| **macOS / Linux** | `curl -fsSL https://openclaw.ai/install.sh \| bash` |
| **macOS / Linux (no root)** | `curl -fsSL https://openclaw.ai/install-cli.sh \| bash` |
| **Windows (PowerShell)** | `iwr -useb https://openclaw.ai/install.ps1 \| iex` |

### Install from Source

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install
pnpm ui:build
pnpm build
openclaw onboard
```

### Install Options

| Option | install.sh | install.ps1 |
|--------|-----------|-------------|
| Skip onboard | `--no-onboard` | `-NoOnboard` |
| Git install | `--install-method git` | `-InstallMethod git` |
| Beta | `--beta` | `-Tag beta` |
| Dry run | `--dry-run` | `-DryRun` |
| CI/automation | `--no-prompt --no-onboard` | `-NoOnboard` |

### Platform-Specific Notes

**macOS**: Auto-installs Homebrew + Node 22. Gateway can be installed as LaunchAgent via `openclaw gateway install`.

**Linux**: Node runtime recommended (not Bun). Gateway installed as systemd user service:
```bash
openclaw onboard --install-daemon
# or manually:
systemctl --user enable --now openclaw-gateway.service
```

**Windows**: Recommended to run via **WSL2 (Ubuntu)**:
```powershell
# 1. Install WSL2
wsl --install -d Ubuntu-24.04
# 2. Enable systemd
echo -e "[boot]\nsystemd=true" | sudo tee /etc/wsl.conf
wsl --shutdown
# 3. Install OpenClaw in WSL (same as Linux)
```

To access WSL Gateway from outside (LAN exposure):
```powershell
# PowerShell (Admin) — port forwarding
$WslIp = (wsl -d Ubuntu-24.04 -- hostname -I).Trim().Split(" ")[0]
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=18789 connectaddress=$WslIp connectport=18789
```

## Onboarding

### Interactive Wizard

```bash
openclaw onboard --install-daemon   # Recommended: includes Gateway service install
openclaw onboard                    # Don't install Gateway service
openclaw configure                  # Config only (already installed OpenClaw)
```

`openclaw onboard` asks in order:

| Step | Question | Recommended | Notes |
|------|----------|-------------|-------|
| 1 | Workspace path | Default `~/.openclaw/workspace` | Press Enter |
| 2 | Model provider | **Anthropic** | Most stable, native support |
| 3 | API Key | From [console.anthropic.com](https://console.anthropic.com) | Paste it |
| 4 | Model | **claude-sonnet-4-5** | Best value |
| 5 | Gateway daemon | **Yes** | Auto-start, runs in background |
| 6 | Channel | Skip for now | Configure separately later |

> 💡 If no Anthropic API Key, use [OpenRouter](https://openrouter.ai) for free credits.

### After Onboarding → First Steps

```bash
# 1. Verify Gateway is running
openclaw health

# 2. Open WebChat (zero config, built-in)
open http://127.0.0.1:18789/    # macOS
# or browser open http://127.0.0.1:18789/

# 3. Send "hi" → should get Agent reply
# This proves: Gateway ✅ Model ✅ Auth ✅ Agent ✅
```

## Quick Start (5 Minutes)

Fastest path — zero to Agent conversation:

```bash
# 1. Install (auto-installs Node.js + OpenClaw)
curl -fsSL https://openclaw.ai/install.sh | bash

# 2. Onboard (choose Anthropic + claude-sonnet-4-5 + install Gateway)
openclaw onboard --install-daemon

# 3. Verify
openclaw health

# 4. Experience! Open WebChat
open http://127.0.0.1:18789/   # macOS
# Send "hi" 🎉
```

### Next: Choose a Channel

| Difficulty | Channel | Config Method | Time |
|------------|---------|---------------|------|
| ⭐ | **WebChat** | Zero config, built-in | 0 min |
| ⭐⭐ | **Telegram** | Get token from @BotFather → configure | 5 min |
| ⭐⭐⭐ | **WhatsApp** | QR pairing, most features | 10 min |
| ⭐⭐⭐ | **Discord** | Create Bot Application → configure | 15 min |

```bash
# Configure Channel (Telegram example)
# 1. Find @BotFather in Telegram → /newbot → get token
# 2. Set token:
openclaw channels add telegram --token "<your-bot-token>"
# 3. Verify:
openclaw channels status --probe
```

## Gateway Management

```bash
# Service management
openclaw gateway install     # Install as system service
openclaw gateway start       # Start
openclaw gateway stop        # Stop
openclaw gateway restart     # Restart
openclaw gateway status      # Status

# Health checks
openclaw health              # Basic health
openclaw status --deep       # Deep status
openclaw doctor              # Diagnose + fix
```

### Multi-Gateway (Same Machine)

Use `--profile` to isolate:
```bash
openclaw --profile main gateway --port 18789
openclaw --profile rescue gateway --port 19001
```

⚠️ Port spacing ≥ 20 (browser/canvas derived ports avoid conflicts)

## Remote Access

### SSH Tunnel

```bash
# From laptop to remote Gateway (recommended: add IdentitiesOnly and specific key)
ssh -N -L 18789:127.0.0.1:18789 \
  -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 \
  user@gateway-host &

# Then local CLI direct connect
openclaw health
openclaw status --deep
```

### SSH Troubleshooting (Tiered Approach)

⚠️ **Before any remote operation, confirm current execution environment**:
```bash
echo "🖥️ Current: $(hostname) | $(whoami) | $(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')"
```

SSH failure tiered troubleshooting order: **Network → Handshake → Authentication**

| Layer | Check Command | Normal Output | Issue Indicates |
|-------|-------------|---------------|-----------------|
| **Network** | `tailscale ping <host>` or `nc -zv <host> 22` | `Open` / `pong` | Tailscale offline or firewall |
| **Handshake** | `ssh -v user@host 2>&1 \| head -20` | `SSH-2.0-OpenSSH` | `Host key verification failed` → fix fingerprint |
| **Auth** | `ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 user@host` | Login success | `Permission denied` → check authorized_keys |

### SSH Best Practices

```bash
# 1. Always use IdentitiesOnly + specific key (avoid Too many authentication failures)
ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 user@host

# 2. Precise Host key conflict removal (don't delete entire known_hosts)
ssh-keygen -R <host-ip>

# 3. Remote machine authorized_keys permissions must be strict
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chown -R $(whoami):staff ~/.ssh   # macOS
# chown -R $(whoami):$(whoami) ~/.ssh  # Linux

# 4. Local loopback verification (confirm sshd + authorized_keys both work)
ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 $(whoami)@127.0.0.1

# 5. After success, record public key fingerprint (for quick comparison later)
ssh-keygen -lf ~/.ssh/id_ed25519.pub
```

### Tailscale

```bash
# Join machines to same Tailnet
tailscale up
tailscale status

# Gateway publishes discovery info
export OPENCLAW_TAILNET_DNS=my-gateway
export OPENCLAW_SSH_PORT=22
```

### CLI Remote Defaults

```json5
// ~/.openclaw/openclaw.json
{
  gateway: {
    mode: "remote",
    remote: {
      url: "ws://127.0.0.1:18789",
      token: "your-token",
    },
  },
}
```

## Debugging

### Log Locations

| Platform | Path |
|----------|------|
| macOS | `~/Library/Logs/OpenClaw/` or `~/.openclaw/logs/` |
| Linux | `journalctl --user -u openclaw-gateway` or `~/.openclaw/logs/` |
| Windows/WSL | Same as Linux inside WSL |

### Common Diagnostic Commands

```bash
openclaw doctor                     # Auto diagnose + fix
openclaw health                     # Gateway health
openclaw status --deep --all        # All components deep status
openclaw channels status --probe    # Channel connection probe
openclaw agents list --bindings     # Agent routing check
openclaw plugins list               # Plugin loading status
openclaw plugins doctor             # Plugin diagnostics
```

### Common Issues

| Issue | Diagnose | Fix |
|-------|----------|-----|
| Gateway won't start | `openclaw doctor` | Check port: `lsof -i :18789` |
| Channel connection failed | `openclaw channels status --probe` | Check token/credentials |
| Node can't connect | `tailscale status` + ping | Check Tailscale status |
| Skill not loading | `openclaw status --deep` | Check workspace path |
| Auth failed | `openclaw status --all` | Re-run `openclaw onboard` |
| npm EACCES (Linux) | `npm config get prefix` | Use `install-cli.sh` to install to `~/.openclaw` |
| openclaw command not found | `which openclaw` | Check PATH |
| WSL portproxy invalid | `netsh interface portproxy show all` | WSL IP changed — reconfigure |
| SSH Host key error | `ssh -v user@host 2>&1 \| grep "Host key"` | `ssh-keygen -R <host>` to clear old fingerprint |
| SSH Too many auth failures | `ssh -v user@host 2>&1 \| grep -c "Offering"` | Add `-o IdentitiesOnly=yes -i <key>` |
| SSH Permission denied | `ssh -o IdentitiesOnly=yes -i <key> user@host` | Check remote `~/.ssh/authorized_keys` permissions (700/600) |

## Networking

See `references/multi-node-networking.md` in `openclaw-dev-knowledgebase`:

- Tailscale interconnect (cross-region encrypted tunnel)
- Single Gateway + remote Node topology
- master/worker agent delegation
- Node visibility queries

## Monitoring

### Node Status Query

Follow FSFR principle, tiered queries (see `references/status-runbook.md`):

```bash
# Environment detection (first confirm openclaw availability)
command -v openclaw && openclaw --version || echo "NO_OPENCLAW"
test -f ~/.openclaw/openclaw.json && echo "HAS_CONFIG" || echo "NO_CONFIG"

# Normal mode (when openclaw available, 1 command gets 80% info)
openclaw health && openclaw status --deep --all

# Degraded mode (openclaw unavailable but config exists)
jq '{gateway: .gateway, agents: [.agents.list[] | {id,name,model}]}' ~/.openclaw/openclaw.json
```

## Operation Runbooks

These runbooks provide complete step-by-step operation guides:

| Operation | Reference | Purpose |
|-----------|-----------|---------|
| **Systematic Diagnosis** | `references/diagnose-runbook.md` | 5-step methodology analysis + structured report + fault pattern precipitation |
| **Config Validation** | `references/lint-config-runbook.md` | Validate openclaw.json syntax/security/paths/Auth |
| **Status Dashboard** | `references/status-runbook.md` | Tiered status query (FSFR) + degradation strategy + formatted output |
