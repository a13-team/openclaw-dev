# OpenClaw Deep Reference — Sessions, Memory, Automation, Security

<!-- Updated: 2026-04-08 -->

## Sessions

### Session Key Mapping

| Source | Key Format |
|--------|-----------|
| DM (default) | `agent:<agentId>:<mainKey>` |
| DM (per-channel-peer) | `agent:<agentId>:<channel>:dm:<peerId>` |
| DM (per-account-channel-peer) | `agent:<agentId>:<channel>:<accountId>:dm:<peerId>` |
| Group chat | `agent:<agentId>:<channel>:group:<id>` |
| Cron | `cron:<jobId>` |
| Webhook | `hook:<uuid>` |
| Node | `node-<nodeId>` |

### DM Isolation (dmScope)

```json5
{
  session: {
    dmScope: "per-channel-peer",  // Recommended for multi-user scenarios
    // Merge same person across channels:
    identityLinks: {
      alice: ["telegram:123", "discord:987654321"],
    },
  },
}
```

⚠️ Default `main` — all DMs share session. Multi-user scenarios must set `per-channel-peer`.

### Lifecycle

- **Daily reset**: Default 4:00 AM (Gateway host local time)
- **Idle reset**: `session.reset.idleMinutes` (optional)
- Both set → whichever expires first triggers reset
- `/new` or `/reset` for manual reset

### State Storage

```
~/.openclaw/agents/<agentId>/sessions/
├── sessions.json          # session key → metadata
└── <sessionId>.jsonl     # Complete conversation log
```

Sessions stored as JSONL at: `~/.openclaw/agents/<agentId>/sessions/<SessionId>.jsonl`

### Maintenance

```json5
{
  session: {
    maintenance: {
      mode: "enforce",       // warn | enforce
      pruneAfter: "30d",
      maxEntries: 500,
      rotateBytes: "10mb",
      maxDiskBytes: "1gb",
    },
  },
}
```

### Common Commands

```bash
openclaw status                      # Overview
openclaw sessions --json             # All sessions
openclaw sessions cleanup --dry-run  # Preview cleanup
/status                              # Status in chat
/context list                        # System prompt contents
/compact                             # Manual compaction
/stop                                # Stop current run
```

---

## Memory

### Memory Files

```
workspace/
├── memory/YYYY-MM-DD.md    # Daily memory (append-only)
└── MEMORY.md               # Long-term memory (only main session loads)
```

- Decisions/preferences/persistent facts → `MEMORY.md`
- Daily notes/context → `memory/YYYY-MM-DD.md`
- Session start automatically reads today + yesterday

### Memory Backends

| Backend | Description |
|---------|-------------|
| `builtin` | SQLite storage (default) |
| `qmd` | Local-first (BM25 + vectors + reranking) |
| `honcho` | AI-native memory system |

### Dreaming (Experimental)

Opt-in experimental feature for automatic memory promotion:
- Scheduled via cron
- Thresholded promotions to long-term memory
- Diary stored in `DREAMS.md`

### Vector Search

```json5
{
  agents: {
    defaults: {
      memorySearch: {
        provider: "openai",  // openai | gemini | voyage | mistral | local
        model: "text-embedding-3-small",
        query: {
          hybrid: {
            enabled: true,
            vectorWeight: 0.7,
            textWeight: 0.3,
            mmr: { enabled: true, lambda: 0.7 },
            temporalDecay: { enabled: true, halfLifeDays: 30 },
          },
        },
      },
    },
  },
}
```

| Feature | Description |
|---------|-------------|
| **Hybrid** | BM25 (keyword) + Vector (semantic) fusion |
| **MMR** | Deduplication, avoid similar fragments repeating |
| **Temporal decay** | Old memory scores decay (30-day half-life) |
| **QMD** | Optional local sidecar (BM25+vectors+reranking) |

### Tools

- `memory_search` — semantic search (snippets + file + line)
- `memory_get` — read specific file/line range

### Auto Flush

Session nearing compaction automatically triggers silent turn, reminding model to write memory to disk.

---

## Automation

### Cron Jobs

Gateway built-in scheduler. Jobs persisted at `~/.openclaw/cron/jobs.json`.

#### Two Execution Modes

| Mode | Session | Payload | Use Case |
|------|---------|---------|----------|
| **Main** | main session | systemEvent | Execute in heartbeat |
| **Isolated** | `cron:<jobId>` | agentTurn | Independent turn, doesn't affect main chat |

#### Quick Create

```bash
# One-time reminder
openclaw cron add --name "Reminder" --at "20m" \
  --session main --system-event "Check calendar" --wake now

# Regular isolated job + deliver to WhatsApp
openclaw cron add --name "Morning brief" --cron "0 7 * * *" \
  --tz "America/Los_Angeles" --session isolated \
  --message "Summarize overnight updates." \
  --announce --channel whatsapp --to "+15551234567"

# With model override
openclaw cron add --name "Deep analysis" --cron "0 6 * * 1" \
  --session isolated --model "opus" --thinking high \
  --message "Weekly analysis" --announce
```

#### Delivery Modes

| delivery.mode | Behavior |
|---------------|----------|
| `announce` | Deliver to specified channel (default) |
| `webhook` | POST to URL |
| `none` | Internal only |

#### Management

```bash
openclaw cron list
openclaw cron run <jobId>
openclaw cron edit <jobId> --message "Updated"
openclaw cron runs --id <jobId>
```

### Heartbeat

- `/heartbeat` internally scheduled (non-cron)
- `HEARTBEAT.md` defines heartbeat checklist
- `wakeMode: "now"` vs `"next-heartbeat"` controls wake timing
- Default interval: ~30 minutes

### Task Flow

Durable orchestration for complex multi-step workflows:
- Revision tracking
- Persistent task state
- Fallback chains

### Standing Orders

Persistent instructions in `AGENTS.md`:
- Re-read on each session start
- Survives compaction
- Best for workflow rules and conventions

---

## Security

### Trust Model

**Personal Assistant Model** — one trust boundary per Gateway. Does not support adversarial multi-tenancy.

### Security Audit

```bash
openclaw security audit          # Quick audit
openclaw security audit --deep   # Deep (includes Gateway probe)
openclaw security audit --fix    # Auto-fix
```

### Hardening Baseline (60s)

```json5
{
  gateway: { mode: "local", bind: "loopback",
    auth: { mode: "token", token: "long-random-token" } },
  session: { dmScope: "per-channel-peer" },
  tools: {
    profile: "messaging",
    deny: ["group:automation", "group:runtime", "group:fs",
           "sessions_spawn", "sessions_send"],
    fs: { workspaceOnly: true },
    exec: { security: "deny", ask: "always" },
    elevated: { enabled: false },
  },
  channels: {
    whatsapp: { dmPolicy: "pairing",
      groups: { "*": { requireMention: true } } },
  },
}
```

### Credential Storage

| Path | Content |
|------|---------|
| `~/.openclaw/credentials/whatsapp/<account>/` | WhatsApp session |
| `~/.openclaw/agents/<id>/agent/auth-profiles.json` | Model API keys |
| `~/.openclaw/secrets.json` | Optional file-backed secrets |
| `~/.openclaw/openclaw.json` | All config (including tokens) |

### Permission Hardening

```bash
chmod 700 ~/.openclaw
chmod 600 ~/.openclaw/openclaw.json
```

### Exec Approvals

Configure approval policy for exec commands:
- `exec.security: "deny"` — block all exec by default
- `exec.ask: "always"` — always ask for approval
- Allowlist specific commands or agents

---

## Sandboxing

Optional Docker container isolation. Gateway stays on host, tools execute in containers.

### Modes

| mode | Description |
|------|-------------|
| `off` | No sandbox |
| `non-main` | Non-main sessions only |
| `all` | All sessions |

### Scope

| scope | Container |
|-------|-----------|
| `session` | One per session |
| `agent` | One per agent |
| `shared` | All share one |

### Workspace Access

| workspaceAccess | Behavior |
|----------------|----------|
| `none` | Sandboxes have independent workspace |
| `ro` | Read-only mount agent workspace to `/agent` |
| `rw` | Read-write mount to `/workspace` |

### Minimal Config

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "non-main",
        scope: "session",
        workspaceAccess: "none",
      },
    },
  },
}
```

### Setup

```bash
scripts/sandbox-setup.sh          # Build sandbox image
scripts/sandbox-browser-setup.sh  # Build browser sandbox
```

### Debug

```bash
openclaw sandbox explain  # View active sandbox mode and policies
```

### Notes

- Default containers have **no network** (`network: "none"`)
- `setupCommand` needs network and root
- `tools.elevated` bypasses sandbox to execute directly on host
- `network: "host"` is forbidden

---

## Hooks

Lifecycle event hooks for extensibility:

| Hook | Trigger |
|------|---------|
| `before_model_resolve` | Before model is selected |
| `before_prompt_build` | Before prompt is assembled |
| `before_agent_start` | Before agent starts |
| `before_agent_reply` | Before agent reply is sent |
| `agent_end` | After agent completes |
| `before_tool_call` | Before tool execution |
| `after_tool_call` | After tool execution |
| `tool_result_persist` | After tool result storage |
| `message_received` | When message arrives |
| `message_sending` | Before message is sent |
| `message_sent` | After message is sent |
| `session_start` | When session starts |
| `session_end` | When session ends |
| `before_compaction` | Before session compaction |
| `after_compaction` | After session compaction |
