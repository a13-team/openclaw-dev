# OpenClaw Source Code Map

<!-- Updated: 2026-04-08 -->

## Core (`src/`)

```
src/
├── cli/                # CLI wiring, argument parsing, entry point
│   └── index.ts        # Main CLI entry → commands dispatch
├── commands/           # CLI subcommands
│   ├── gateway.ts      # `openclaw gateway` — start/manage Gateway
│   ├── agent.ts        # `openclaw agent` — interact with Pi agent
│   ├── message.ts      # `openclaw message` — send via channels
│   └── ...
├── gateway/            # Gateway WS server
│   ├── index.ts        # WS server setup, connection management, routing
│   └── doctor.ts       # `openclaw doctor` — health checks
├── agent/              # Pi agent core integration
├── sessions/           # Session management (main, group, queue)
├── channels/           # Channel routing layer
├── routing/            # Message routing between channels/agents
├── config/             # Configuration system
├── browser/            # Browser control (CDP — Chrome DevTools Protocol)
├── canvas-host/        # Canvas + A2UI (Agent-to-UI)
├── web/                # WebChat + web provider
├── plugins/            # Plugin loading and management
├── providers/          # Model providers (Anthropic, OpenAI, etc.)
├── media/              # Media pipeline (images, audio, video)
├── tts/                # Text-to-speech
├── cron/               # Cron jobs + timed wakeups
├── hooks/              # Event hook system
├── wizard/             # Onboarding wizard (`openclaw onboard`)
├── terminal/           # Terminal utilities
│   ├── table.ts        # Table formatting
│   └── palette.ts      # Color palette (lobster palette)
└── ...
```

## Lobster Color Palette

Used throughout OpenClaw UI and terminal output:

| Token | Hex | Usage |
|-------|-----|-------|
| `accent` | `#FF5A2D` | Primary accent color |
| `success` | `#2FBF71` | Success states |
| `warn` | `#FFB020` | Warning states |
| `error` | `#E23D2D` | Error states |

## Extensions (`extensions/`) — 39 packages

### Channels
| Extension | Protocol |
|-----------|----------|
| `bluebubbles` | iMessage via BlueBubbles |
| `discord` | Discord (discord.js) |
| `slack` | Slack (Bolt SDK) |
| `telegram` | Telegram (grammY) |
| `whatsapp` | WhatsApp (Baileys) |
| `signal` | Signal |
| `imessage` | iMessage (native) |
| `msteams` | Microsoft Teams |
| `matrix` | Matrix |
| `googlechat` | Google Chat |
| `feishu` | Feishu / Lark |
| `mattermost` | Mattermost |
| `irc` | IRC |
| `nostr` | Nostr protocol |
| `line` | LINE |
| `zalo` / `zalouser` | Zalo |
| `synology-chat` | Synology Chat |
| `nextcloud-talk` | Nextcloud Talk |
| `tlon` | Tlon / Urbit |
| `twitch` | Twitch chat |
| `bluebubbles` | BlueBubbles iMessage |

### Memory & Storage
| Extension | Purpose |
|-----------|---------|
| `memory-core` | Core memory plugin |
| `memory-lancedb` | LanceDB vector memory |

### Tools & Utilities
| Extension | Purpose |
|-----------|---------|
| `lobster` | Workflow shell |
| `llm-task` | LLM task execution |
| `phone-control` | Phone remote control |
| `device-pair` | Device pairing |
| `talk-voice` | Voice conversation |
| `voice-call` | Voice calling |
| `diagnostics-otel` | OpenTelemetry diagnostics |
| `thread-ownership` | Thread management |
| `copilot-proxy` | Copilot proxy |
| `open-prose` | Prose editing |
| `acpx` | ACP exchange |

### Auth Helpers
| Extension | Purpose |
|-----------|---------|
| `google-gemini-cli-auth` | Gemini CLI auth |
| `minimax-portal-auth` | Minimax portal auth |
| `qwen-portal-auth` | Qwen portal auth |

## Apps (`apps/`)

| App | Tech | Description |
|-----|------|-------------|
| `macos/` | SwiftUI | Menu bar app, Voice Wake, Talk Mode |
| `ios/` | Swift | iOS node (Canvas, camera) |
| `android/` | Kotlin | Android node |

## Scripts (`scripts/`)

| Script | Purpose |
|--------|---------|
| `run-node.mjs` | Run Node.js processes (gateway/agent/TUI) |
| `package-mac-app.sh` | macOS app packaging + signing |
| `restart-mac.sh` | Restart macOS app |
| `clawlog.sh` | macOS unified log viewer |
| `lib/plugin-sdk-entrypoints.json` | Plugin SDK subpaths (200+ exports) |

## Plugin SDK Entry Points

Import from specific subpaths only:

```typescript
import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";
import { createChatChannelPlugin } from "openclaw/plugin-sdk/channel-core";
import { defineSingleProviderPluginEntry } from "openclaw/plugin-sdk/core";
```

### Key Subpaths

| Category | Subpaths |
|----------|----------|
| Plugin Entry | `plugin-entry`, `channel-plugin`, `setup-plugin` |
| Channel | `channel-core`, `channel-setup`, `setup-runtime`, `setup-tools` |
| Account | `account-core`, `account-id`, `account-resolution`, `account-helpers` |
| Messaging | `inbound-envelope`, `inbound-reply-dispatch`, `messaging-targets` |
| Outbound | `outbound-media`, `outbound-runtime` |
| Config | `config-schema` |

Full list of 200+ subpaths: `scripts/lib/plugin-sdk-entrypoints.json`

### Deprecated Subpaths

Do not use (use generic SDK subpaths instead):
- `plugin-sdk/slack`
- `plugin-sdk/discord`
- `plugin-sdk/signal`
- `plugin-sdk/whatsapp`

## Source Code Organization

### Key Directories

| Directory | Purpose |
|----------|---------|
| `src/cli/` | Command-line interface entry points |
| `src/gateway/` | WebSocket server, connection handling |
| `src/agent/` | Pi agent core integration |
| `src/channels/` | Channel implementations |
| `src/plugins/` | Plugin loading and management |
| `src/providers/` | LLM provider integrations |
| `src/terminal/` | Terminal UI utilities, color palette |
| `scripts/lib/` | Build and utility scripts |

### Build Commands

```bash
pnpm install          # Install dependencies
pnpm build            # Build all packages
pnpm ui:build         # Build UI components
pnpm gateway:watch    # Watch mode for gateway development
pnpm gateway:dev       # Dev bootstrap
```
