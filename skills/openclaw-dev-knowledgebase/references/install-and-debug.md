# OpenClaw Installation and Debug Reference

<!-- Updated: 2026-04-08 -->

## Installation

### Quick Install

| Platform | Command |
|---------|--------|
| **macOS / Linux** | `curl -fsSL https://openclaw.ai/install.sh \| bash` |
| **macOS / Linux (no root)** | `curl -fsSL https://openclaw.ai/install-cli.sh \| bash` |
| **Windows (PowerShell)** | `iwr -useb https://openclaw.ai/install.ps1 \| iex` |

### Installer Options

| Option | install.sh | install.ps1 |
|--------|-----------|-------------|
| Skip onboard | `--no-onboard` | `-NoOnboard` |
| Git install | `--install-method git` | `-InstallMethod git` |
| Beta | `--beta` | `-Tag beta` |
| Dry run | `--dry-run` | `-DryRun` |
| CI/automation | `--no-prompt --no-onboard` | `-NoOnboard` |

### From Source

```bash
git clone https://github.com/openclaw/openclaw.git && cd openclaw
pnpm install && pnpm ui:build && pnpm build
openclaw onboard
```

### Platform-Specific Notes

**macOS**: Auto-installs Homebrew + Node 22. Gateway installed as LaunchAgent.

**Linux**: Node runtime recommended (not Bun — Bun has WhatsApp/Telegram bugs). Gateway installed as systemd user service:
```bash
openclaw onboard --install-daemon
systemctl --user enable --now openclaw-gateway.service
```

**Windows**: Recommended to run via **WSL2 (Ubuntu)**:
```powershell
wsl --install -d Ubuntu-24.04
# Enable systemd:
# /etc/wsl.conf → [boot] systemd=true
# Then wsl --shutdown && reopen
# Install in WSL same as Linux
```

WSL port exposure (PowerShell Admin):
```powershell
$WslIp = (wsl -d Ubuntu-24.04 -- hostname -I).Trim().Split(" ")[0]
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=18789 connectaddress=$WslIp connectport=18789
```

---

## Debugging

### Debug Mode

Enable runtime overrides for debugging:
```bash
/debug
```

This enables `commands.debug: true` in config, allowing temporary config overrides.

### Logging

```bash
# Verbose logging
openclaw gateway --verbose

# Raw stream logging
OPENCLAW_RAW_STREAM=1

# Raw chunk logging
PI_RAW_STREAM=1

# Trace-level logging
openclaw gateway --verbose --log-level trace
```

### Dev Profile

Use `--dev` profile for isolated development:
```bash
openclaw --dev
# Isolates to ~/.openclaw-dev, shifts default ports
```

### Dev Commands

```bash
# Watch mode for fast iteration
pnpm gateway:watch

# Dev bootstrap
pnpm gateway:dev
```

### Gateway Port Conflicts

If port is already in use:
```bash
openclaw gateway --force
# Kills existing process on same port
```

---

## Log Locations

| Platform | Path |
|----------|------|
| macOS | `~/Library/Logs/OpenClaw/` or `~/.openclaw/logs/` |
| Linux | `journalctl --user -u openclaw-gateway` or `~/.openclaw/logs/` |
| Windows/WSL | Same as Linux inside WSL |

### Diagnostic Commands

```bash
openclaw doctor                     # Auto diagnose + fix
openclaw health                     # Gateway health
openclaw status --deep --all        # Deep status
openclaw channels status --probe    # Channel probe
openclaw agents list --bindings     # Agent routing
openclaw plugins list               # Plugin status
openclaw plugins doctor             # Plugin diagnostics
```

---

## Common Issues

| Issue | Diagnose | Fix |
|-------|----------|-----|
| Gateway won't start | `openclaw doctor` | `lsof -i :18789` check port |
| Channel connection failed | `openclaw channels status --probe` | Check token |
| Skill not loading | `openclaw status --deep` | Check workspace path |
| npm EACCES (Linux) | `npm config get prefix` | Use `install-cli.sh` |
| openclaw not found | `which openclaw` | Check PATH |
| WSL portproxy invalid | `netsh interface portproxy show all` | WSL IP changed — reconfigure |
| Config corruption | `jq . ~/.openclaw/openclaw.json` | Restore from `.bak` |
| Auth failures | `openclaw status --all` | Re-run `openclaw onboard` |

---

## Gateway Startup

```bash
# Standard
openclaw gateway --port 18789 --verbose --force

# Force kill port conflict
openclaw gateway --force

# Health check
openclaw gateway status

# Deep status
openclaw status --deep --all
```

### Channel Probe

```bash
openclaw channels status --probe
```

### Config Reload

OpenClaw uses hybrid mode:
1. Watch config file for changes
2. Atomic swap to new config
3. No restart needed for most changes

---

## Security Audit

```bash
# Quick audit
openclaw security audit

# Deep audit (includes Gateway probe)
openclaw security audit --deep

# Auto-fix issues
openclaw security audit --fix
```
