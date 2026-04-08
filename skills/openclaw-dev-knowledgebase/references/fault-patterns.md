# OpenClaw Fault Patterns Library (Living Document)

<!-- Updated: 2026-04-08 -->

> **This is a living document.** Agents should append new patterns discovered during diagnosis to the appropriate category.
> Format: Signature → Root Cause → Fix → Prevention.

---

## Network Layer Failures

### fetch failed Spike
- **Signature**: `TypeError: fetch failed` > 100 times/day
- **Associated Signature**: `ERR_ASSERTION: Reached illegal state! IPV4 address change`
- **Root Cause**: Unstable network interface — WiFi disconnection, VPN/Clash client restart, external drive disconnect causing node unavailable
- **Impact**: All outbound HTTP requests fail, Agent completely unable to call LLM API
- **Fix**:
  1. `ifconfig | grep "inet "` check network interfaces
  2. Check VPN/proxy status
  3. If node on external drive: `which node` → confirm path available
- **Prevention**: Install node on system drive, not external drives
- **First Found**: 2026-01-30 (5,330 times/day)

### DNS Hijacked by Proxy
- **Signature**: `resolves to private/internal/special-use IP address`
- **Root Cause**: VPN/Clash proxy redirects public domain DNS to local proxy IP, OpenClaw security policy rejects private IP connections
- **Impact**: `web_fetch` tool fails for all public URLs
- **Fix**:
  1. `dig google.com` → if returns 127.x or 10.x → proxy hijacking
  2. Temporarily disable proxy DNS hijacking
  3. Or set OpenClaw URL security policy to allow proxy IPs
- **Prevention**: Configure proxy bypass list to include OpenClaw common domains
- **First Found**: 2026-02-26 (38 times)

---

## Configuration Layer Failures

### JSON Syntax Error
- **Signature**: `invalid character` + line number + `config reload skipped`
- **Root Cause**: Manual editing of `openclaw.json` introduced syntax error (extra comma, illegal quotes, missing brackets)
- **Impact**: Config hot-reload skipped → Agent can't read API key → all tasks terminate
- **Fix**:
  1. `jq . ~/.openclaw/openclaw.json` → see error line
  2. Fix syntax error
  3. Or restore from recent `.bak`: `ls -lt ~/.openclaw/openclaw.json.bak* | head -1`
- **Prevention**: Before editing `cp openclaw.json openclaw.json.bak-$(date +%Y%m%d-%H%M%S)`, after editing `jq . openclaw.json > /dev/null`
- **First Found**: 2026-02-04 (706 times, line 193 comma error)
- **Recurrence**: 2026-02-12 (5,347 times, line 763 quote error)

### API Key Lost
- **Signature**: `No API key found for provider` + `Configure auth for this agent`
- **Root Cause**: Usually cascade effect of config corruption, or auth-profiles.json accidentally deleted
- **Impact**: Specific Agent unable to call LLM
- **Fix**:
  1. First check if config corrupted: `jq . ~/.openclaw/openclaw.json`
  2. Check auth profile: `cat ~/.openclaw/agents/<id>/agent/auth-profiles.json`
  3. Re-configure: `openclaw agents add <id>`
- **First Found**: 2026-02-04

### Refusing to Bind Gateway Without Auth
- **Signature**: `refusing to bind gateway ... without auth` (non-loopback without valid auth)
- **Root Cause**: Gateway configured to listen on non-loopback address without valid auth token configured
- **Impact**: Gateway refuses to start, binding fails
- **Fix**:
  1. Set `bind: "loopback"` or configure valid auth token
  2. For remote access, use Tailscale instead of public IP
- **Prevention**: Use loopback bind for local-only access
- **First Found**: 2026-04-08 (new pattern)

### EADDRINUSE (Port Conflict)
- **Signature**: `EADDRINUSE: address already in use :::18789`
- **Root Cause**: Old Gateway process didn't exit, other application占用, or multi-profile port conflict
- **Impact**: Gateway unable to start, onboard last step fails
- **Fix**:
  1. `lsof -i :18789` find占用 process
  2. `kill <PID>` or `openclaw gateway stop`
  3. Or change port: `openclaw gateway --port 19000`
- **Prevention**: Before onboard, confirm port is free with `lsof -i :18789`
- **First Found**: 2026-02-28

### Gateway Start Blocked: Set gateway.mode=local
- **Signature**: `gateway start blocked: set gateway.mode=local` (remote mode config error)
- **Root Cause**: Gateway configured with `mode: "remote"` but trying to start as local server
- **Impact**: Gateway fails to start
- **Fix**:
  1. Check `openclaw.json` gateway configuration
  2. Set `gateway.mode: "local"` or remove remote configuration
  3. Or set proper remote URL if remote mode intended
- **Prevention**: Match gateway mode to intended use case
- **First Found**: 2026-04-08 (new pattern)

### Unauthorized During Connect
- **Signature**: `unauthorized during connect` (auth mismatch)
- **Root Cause**: Auth token mismatch between client and Gateway
- **Impact**: Client cannot connect to Gateway
- **Fix**:
  1. Check `gateway.auth.token` in config matches client's expected token
  2. Re-run onboard to regenerate auth credentials
  3. Verify client connecting to correct Gateway instance
- **Prevention**: Consistent auth configuration across client and server
- **First Found**: 2026-04-08 (new pattern)

---

## Process Layer Failures

### Gateway Crash Loop
- **Signature**: 3+ `Gateway listening` / PID changes within 10 minutes
- **Associated Signature**: PID interval < 60 seconds, PID overflow wrap (e.g., from 88570 to 3018)
- **Root Cause**: Startup crash, LaunchAgent KeepAlive keeps restarting
  - Common triggers: node binary unavailable (external drive), port occupied, severe config corruption
- **Impact**: System resource consumption, log explosion, process table explosion
- **Fix**:
  1. `launchctl unload ~/Library/LaunchAgents/openclaw-gateway*.plist` to stop first
  2. Check node path: `which node` → should not be on `/Volumes/`
  3. Check port: `lsof -i :18789`
  4. Manual start to see error: `openclaw gateway --port 18789`
- **Prevention**:
  - Install node on system drive
  - LaunchAgent add `ThrottleInterval` ≥ 120
  - Configure `bind: "loopback"` (not `0.0.0.0`)
- **First Found**: 2026-02-02 (20+ restarts, 10-second intervals)

---

## Plugin Layer Failures

### Plugin Load Errors
- **Signature**: Plugin fails to load with errors in Gateway logs
- **Root Cause**: Plugin manifest invalid, missing dependencies, or version incompatibility
- **Impact**: Plugin functionality unavailable
- **Fix**:
  1. Run `openclaw plugins doctor` to diagnose
  2. Check plugin manifest `openclaw.plugin.json` for errors
  3. Verify plugin version compatibility
  4. Reinstall plugin if needed
- **Prevention**: Test plugins in dev environment before production deployment
- **First Found**: 2026-04-08 (new pattern)

### Config Validation Failure
- **Signature**: Config validation errors during Gateway startup
- **Root Cause**: Invalid values in `openclaw.json` (wrong types, missing required fields)
- **Impact**: Gateway fails to start or behaves incorrectly
- **Fix**:
  1. Run `openclaw doctor --fix` to auto-fix common issues
  2. Manually review config for invalid values
  3. Restore from backup if needed
- **Prevention**: Use `openclaw doctor` regularly to catch config issues early
- **First Found**: 2026-04-08 (new pattern)

---

## Tool Layer Failures

### Browser Not Attached
- **Signature**: `no tab is connected` / `attachOnly not running`
- **Root Cause**: Agent tries to use browser tool but user hasn't activated OpenClaw extension in Chrome
- **Impact**: Browser tool calls fail
- **Fix**: Prompt user to open Chrome → click OpenClaw extension → attach tab
- **Prevention**: Agent checks connection status before using browser
- **First Found**: 2026-02 (25 times)

### Workspace Sandbox Write Blocked
- **Signature**: `sandbox` + write path + `denied`
- **Root Cause**: Workspace sandbox.mode only allows root directory writes, no subdirectory creation
- **Impact**: Agent unable to create new directories/files in workspace
- **Fix**: Check `openclaw.json` agent `sandbox.mode`, change to `lenient` or adjust `sandbox.allowPaths`
- **First Found**: 2026-02-28

### Env Override Blocked by Security Policy
- **Signature**: `[env-overrides] Blocked skill env overrides`
- **Root Cause**: Skill trying to inject API key via environment variable (e.g., FISH_AUDIO_API_KEY), blocked by security policy
- **Impact**: Skills depending on environment variables don't work
- **Fix**: Configure `skills.envOverrides.allow` list in `openclaw.json`
- **First Found**: 2026-02-27

---

## Onboarding Layer Failures

### Node.js Version Incompatible
- **Signature**: `Unsupported Node.js version` / `engine "node" is incompatible`
- **Root Cause**: System-provided or brew-installed Node.js version too old (< 22)
- **Impact**: Install fails or Gateway unable to start
- **Fix**: `node -v` check version; install Node 22+: `brew install node@22` or `nvm install 22`
- **Prevention**: `install.sh` auto-installs Node 22, pay attention to version during manual install
- **First Found**: 2026-02-28

### Port 18789 Occupied
- **Signature**: `EADDRINUSE: address already in use :::18789`
- **Root Cause**: Old Gateway process didn't exit, other application占用, or multi-profile port conflict
- **Impact**: Gateway unable to start, onboard last step fails
- **Fix**:
  1. `lsof -i :18789` find占用 process
  2. `kill <PID>` or `openclaw gateway stop`
  3. Or change port: `openclaw gateway --port 19000`
- **Prevention**: Before onboard, confirm port is free
- **First Found**: 2026-02-28

### API Key Invalid/Expired
- **Signature**: `401 Unauthorized` / `Invalid API key` / `No API key found for provider`
- **Root Cause**: Key pasted with extra spaces/newlines, key revoked, or wrong provider selected
- **Impact**: Gateway running but Agent unable to reply to messages
- **Fix**:
  1. `openclaw models status` check auth status
  2. Re-configure: `openclaw configure` → re-enter API key
  3. Confirm key is valid in provider backend (console.anthropic.com)
- **Prevention**: After pasting, immediately verify with `openclaw health`
- **First Found**: 2026-02-28

### Onboard Disconnected Mid-Way
- **Signature**: Partial config written but Gateway not installed
- **Root Cause**: Terminal unexpectedly closed, SSH disconnect, Ctrl+C interrupt
- **Impact**: Config file incomplete, Gateway doesn't start
- **Fix**: Re-run `openclaw onboard --install-daemon` (idempotent, skips completed steps)
- **Prevention**: Use `tmux` or `screen` when running onboard on remote machine
- **First Found**: 2026-02-28

---

## SSH / Remote Connection Layer Failures

### Host Key Verification Failed
- **Signature**: `Host key verification failed` / `REMOTE HOST IDENTIFICATION HAS CHANGED`
- **Root Cause**: Target machine OS reinstalled, IP reused, or Tailscale IP changed causing `~/.ssh/known_hosts` fingerprint mismatch
- **Impact**: SSH connection refused by client, all remote operations (deploy-skill, diagnose, etc.) fail
- **Fix**:
  1. `ssh-keygen -R <host-ip>` precisely delete old fingerprint (don't delete entire known_hosts)
  2. Reconnect and confirm new fingerprint: `ssh -o StrictHostKeyChecking=ask user@host`
- **Prevention**: Proactively notify all clients to update fingerprints after OS reinstall; record each node's public key fingerprint in operations documentation
- **First Found**: 2026-02-28

### Too Many Authentication Failures
- **Signature**: `Too many authentication failures` / `Received disconnect from ... Too many authentication failures`
- **Root Cause**: SSH agent loaded too many keys (3-5+), client tries each until server disconnects (default `MaxAuthTries=6`)
- **Impact**: Even if correct key exists, cannot login; often mixed with Host key errors causing investigation direction interference
- **Fix**:
  1. Force specify single key when connecting: `ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 user@host`
  2. Or configure in `~/.ssh/config`:
     ```
     Host gateway-*
       IdentitiesOnly yes
       IdentityFile ~/.ssh/id_ed25519
     ```
  3. Clean extra keys from SSH agent: `ssh-add -D && ssh-add ~/.ssh/id_ed25519`
- **Prevention**: All OpenClaw scripts and documentation ssh calls consistently add `IdentitiesOnly=yes`
- **First Found**: 2026-02-28

### authorized_keys Permission Error
- **Signature**: `Permission denied (publickey)` + server `/var/log/auth.log` shows `Authentication refused: bad ownership or modes`
- **Root Cause**: `~/.ssh/authorized_keys` file permission not 600, or `~/.ssh` directory permission not 700, or owner incorrect
- **Associated Symptoms**: Network layer and handshake layer all normal, only auth fails — this is the most common SSH root cause
- **Impact**: Public key auth silently refused by sshd, client only sees `Permission denied`
- **Fix**:
  1. Fix permissions:
     ```bash
     chmod 700 ~/.ssh
     chmod 600 ~/.ssh/authorized_keys
     chown -R $(whoami):staff ~/.ssh   # macOS
     ```
  2. Confirm authorized_keys content is complete single-line public key (no line breaks, no extra spaces)
  3. Local loopback verification: `ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 $(whoami)@127.0.0.1`
- **Prevention**: Use `ssh-copy-id` instead of manual copy; verify permissions immediately after writing
- **First Found**: 2026-02-28

---

## Rate Limit / Quota

### LLM API Rate Limit
- **Signature**: `429` / `rate.limit` / `Too Many Requests`
- **Root Cause**: API call frequency exceeds provider limits
- **Impact**: Agent response delayed or failed
- **Fix**: Reduce concurrency, upgrade API plan, configure fallback model
- **First Found**: 2026-02-24

---

> **When appending new patterns, follow the format above: include Signature, Root Cause, Impact, Fix, Prevention, First Found date.**
