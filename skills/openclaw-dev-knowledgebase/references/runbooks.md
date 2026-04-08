# OpenClaw Operational Runbooks

<!-- Updated: 2026-04-08 -->

Systematic operational procedures for OpenClaw environments.

---

## Gateway Startup

### Standard Startup

```bash
openclaw gateway --port 18789 --verbose --force
```

Flags:
- `--port` — specify port (default 18789)
- `--verbose` — enable verbose logging
- `--force` — kill existing process on same port

### Health Check

```bash
# Basic health
openclaw gateway status

# Full status
openclaw status

# Deep status with all components
openclaw status --deep --all

# Channel connection probe
openclaw channels status --probe
```

### Config Reload

OpenClaw uses hybrid mode for config reload:
1. Watch config file for changes
2. Atomic swap to new config
3. No restart needed for most config changes

For immediate reload:
```bash
openclaw gateway restart
```

---

## Common Failures

### Refusing to Bind Without Auth

**Error**: `refusing to bind gateway ... without auth`

**Cause**: Gateway configured for non-loopback bind without valid auth token

**Fix**:
1. Set `bind: "loopback"` in config for local-only access
2. Or configure valid auth token for remote access
3. Use Tailscale for remote access instead of public IP

### EADDRINUSE (Port Conflict)

**Error**: `EADDRINUSE: address already in use :::18789`

**Cause**: Another process on port 18789

**Fix**:
```bash
# Find占用 process
lsof -i :18789

# Kill it
kill <PID>

# Or use Gateway's force flag
openclaw gateway --port 18789 --force
```

### Gateway Mode Blocked

**Error**: `gateway start blocked: set gateway.mode=local`

**Cause**: Config has conflicting mode settings

**Fix**:
1. Check `gateway.mode` in `openclaw.json`
2. Set `gateway.mode: "local"` or remove remote config
3. Restart Gateway

### Unauthorized Connection

**Error**: `unauthorized during connect`

**Cause**: Auth token mismatch

**Fix**:
1. Verify auth token in config matches client expectations
2. Re-run onboard to regenerate credentials
3. Check client is connecting to correct Gateway

---

## Remote Gateway Login (Tailscale + SSH)

### Prerequisites

- Account assigned (example: `<your-username>`)
- Tailscale client installed and joined same Tailnet
- Local SSH client available

### Standard Login Flow

```bash
# 1. Confirm Tailscale is online
tailscale status

# 2. Find target machine IP (IP may change, confirm each time)
tailscale status | grep <gateway-host>
GATEWAY_IP="100.x.x.x"  # Replace with actual IP

# 3. SSH login (recommended: add IdentitiesOnly)
ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 <your-username>@$GATEWAY_IP

# 4. Check OpenClaw status
openclaw status
openclaw doctor

# 5. Execute tasks
openclaw update
openclaw models list

# 6. Exit
exit
```

### File Transfer

```bash
# Upload
scp -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 \
  ./local_file <your-username>@$GATEWAY_IP:~/

# Download
scp -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 \
  <your-username>@$GATEWAY_IP:~/remote_file ./
```

### Security Red Lines

- ✅ Access only via Tailscale address
- ❌ Do not expose SSH on public IP
- ❌ Do not modify VPN / DNS / routing / firewall
- ❌ Do not modify `/etc/ssh/sshd_config`
- ❌ Do not share accounts, passwords, private keys
- Exit promptly after operations

### Common Issues

| Issue | Troubleshooting |
|-------|----------------|
| Connection timeout | Confirm local Tailscale online + same Tailnet + SSH service running |
| Insufficient permissions | Send full error to admin for authorization |
| `openclaw` not found | First `openclaw doctor`; still fails contact admin to check install and PATH |

### Login Sequence

1. Connect to Tailscale
2. `ssh` login
3. `openclaw doctor`
4. Execute tasks
5. `exit`

> 💡 Configure SSH key login + `IdentitiesOnly=yes` to reduce password input and security risk

---

## Gateway Remote Operations

### Restart Gateway

```bash
# Local
pkill -TERM openclaw-gateway
# launchd auto-restarts; if not:
openclaw gateway run &

# Remote (SSH in then)
pkill -9 -f openclaw-gateway || true
nohup openclaw gateway run --bind loopback --port 18789 --force > /tmp/openclaw-gateway.log 2>&1 &
```

### Health Checks

```bash
openclaw doctor
openclaw channels status --probe
openclaw status --deep
ss -ltnp | rg 18789        # Linux
lsof -i :18789              # macOS
tail -n 120 /tmp/openclaw-gateway.log
```

### Update OpenClaw

```bash
# Remote
sudo npm i -g openclaw@latest
openclaw --version

# Restart Gateway to apply update
pkill -TERM openclaw-gateway
```

### Batch Deploy Skills to Remote

```bash
# rsync entire skills directory (exclude memory)
rsync -avz --exclude 'memory/' --exclude 'MEMORY.md' \
  -e "ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519" \
  skills/ <your-username>@$GATEWAY_IP:~/.openclaw/workspace/skills/

# Then SSH in and send /new to agent, or restart gateway
```

---

## Plugin Operations

### Plugin Diagnostics

```bash
# Check plugin health
openclaw plugins doctor

# List all plugins
openclaw plugins list

# Inspect specific plugin
openclaw plugins inspect <plugin-id>

# Enable/disable plugin
openclaw plugins enable <plugin-id>
openclaw plugins disable <plugin-id>
```

### Common Plugin Issues

| Issue | Fix |
|-------|-----|
| Plugin load errors | Run `openclaw plugins doctor` |
| Config validation failure | Run `openclaw doctor --fix` |
| Missing dependencies | Reinstall plugin |

---

## macOS Operations

### View Gateway Logs

```bash
./scripts/clawlog.sh
# or
log show --predicate 'subsystem == "ai.openclaw"' --last 1h
```

### Restart macOS App

```bash
./scripts/restart-mac.sh
# or manually
killall "OpenClaw" && open -a "OpenClaw"
```

### Permission Checks

macOS requires:
- Accessibility — for browser control
- Screen Recording — for peekaboo / screenshot
- Microphone — for Voice Wake / Talk Mode
- Full Disk Access — for Apple Notes / iMessage skills

---

## Diagnostics Workflow

### 5-Step Systematic Analysis

1. **Gather** — Collect logs, config, status output
2. **Correlate** — Match patterns against fault library
3. **Isolate** — Find root cause
4. **Fix** — Apply remediation
5. **Verify** — Confirm fix worked

### Log Analysis

```bash
# Gateway logs location
# macOS: ~/Library/Logs/OpenClaw/ or ~/.openclaw/logs/
# Linux: journalctl --user -u openclaw-gateway or ~/.openclaw/logs/
# Windows/WSL: Same as Linux inside WSL

# Recent logs
tail -n 200 ~/.openclaw/logs/openclaw-$(date +%Y-%m-%d).log

# Error-only filter
grep -i error ~/.openclaw/logs/openclaw-$(date +%Y-%m-%d).log
```
