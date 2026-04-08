# OpenClaw Plugin Architecture

<!-- Updated: 2026-04-08 -->
<!-- Reference: aligned with 2026-03-26 latest OpenClaw docs -->

## Two Types of Installable Objects

OpenClaw supports two types of installable objects:

1. **Native OpenClaw Plugin**
   - Runs inside Gateway process
   - Uses `openclaw.plugin.json`
   - Declares entry via `package.json` `openclaw.extensions`
   - Can register: tools, channels, providers, hooks, HTTP routes, services, context engines

2. **Compatible Bundle**
   - From Claude / Codex / Cursor ecosystem
   - Shows as `Format: bundle` after install
   - OpenClaw maps supported content (skills, partial commands, supported hook packs, MCP config)
   - Not a native plugin — doesn't require `openclaw.plugin.json`

## Detection Priority

OpenClaw detects directories in this order:

1. `openclaw.plugin.json` or valid `package.json` + `openclaw.extensions` → native plugin
2. `.codex-plugin/`, `.claude-plugin/`, `.cursor-plugin/` or default Claude/Cursor layout → compatible bundle

If a directory has both native and bundle markers, native takes priority.

## Native Plugin Directory Structure

```text
my-plugin/
├── openclaw.plugin.json    # Required: native manifest
├── package.json            # Required: openclaw.extensions
├── index.ts                # Recommended entry in package root
├── skills/                 # Optional: bundled skills
│   └── my-skill/
│       └── SKILL.md
└── src/                    # Optional: helper modules
```

**Key Rules**:
1. Native plugin must have `openclaw.plugin.json`
2. Manifest handles discovery / config validation / auth metadata, not entrypoint
3. Entrypoint declared in `package.json` `openclaw.extensions`
4. `configSchema` is **required** even if plugin has no config (use empty schema)
5. Entry file usually in package root; `openclaw.extensions` must point to actual file in package
6. OpenClaw allows compatible bundle installs, but bundle ≠ native plugin

## Compatible Bundle Directory Structure

### Claude bundle

```text
my-bundle/
├── .claude-plugin/
│   └── plugin.json         # Optional
├── skills/
├── commands/
├── agents/
├── hooks/
├── .mcp.json
└── settings.json
```

### Codex bundle

```text
my-bundle/
├── .codex-plugin/
│   └── plugin.json
├── skills/
├── hooks/
├── .mcp.json
└── .app.json
```

### Cursor bundle

```text
my-bundle/
├── .cursor-plugin/
│   └── plugin.json
├── skills/
├── .cursor/commands/
├── .cursor/agents/
├── .cursor/rules/
└── .mcp.json
```

## Plugin Manifest (`openclaw.plugin.json`)

### Minimal Example

```json
{
  "id": "voice-call",
  "configSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {}
  }
}
```

### Full Example

```json
{
  "id": "openrouter",
  "name": "OpenRouter",
  "description": "OpenRouter provider plugin",
  "version": "1.0.0",
  "providers": ["openrouter"],
  "providerAuthEnvVars": {
    "openrouter": ["OPENROUTER_API_KEY"]
  },
  "providerAuthChoices": [
    {
      "provider": "openrouter",
      "method": "api-key",
      "choiceId": "openrouter-api-key",
      "choiceLabel": "OpenRouter API key",
      "groupId": "openrouter",
      "groupLabel": "OpenRouter",
      "optionKey": "openrouterApiKey",
      "cliFlag": "--openrouter-api-key",
      "cliOption": "--openrouter-api-key <key>",
      "cliDescription": "OpenRouter API key",
      "onboardingScopes": ["text-inference"]
    }
  ],
  "uiHints": {
    "apiKey": {
      "label": "API key",
      "placeholder": "sk-or-v1-...",
      "sensitive": true
    }
  },
  "configSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "apiKey": {
        "type": "string"
      }
    }
  }
}
```

### Top-Level Fields Quick Reference

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Canonical plugin id |
| `configSchema` | Yes | Inline JSON Schema for plugin config |
| `enabledByDefault` | No | Whether bundled plugin is enabled by default |
| `kind` | No | Exclusive category like `memory` / `context-engine` |
| `channels` | No | Channel IDs declared by this plugin |
| `providers` | No | Provider IDs declared by this plugin |
| `providerAuthEnvVars` | No | Cheap env metadata for provider auth |
| `providerAuthChoices` | No | Onboarding / CLI auth choice metadata |
| `skills` | No | Skill directories relative to plugin root |
| `name` | No | Human-readable name |
| `description` | No | Short description |
| `version` | No | Informational version number |
| `uiHints` | No | UI label / placeholder / sensitivity hints for config fields |

### Conflicting Legacy Terms

- `version` in manifest is **valid and optional**
- `uiHints` in manifest is **valid and optional**
- Manifest **no longer declares entrypoint**
- `configSchema` **must exist** even if empty
- `required` is not forbidden — it participates in config validation

## `package.json`

```json
{
  "name": "@myorg/openclaw-my-plugin",
  "version": "1.0.0",
  "type": "module",
  "openclaw": {
    "extensions": ["./index.ts"]
  }
}
```

### Key Rules

- `openclaw.extensions` must point to actual file in package, not directory
- A package can expose multiple extensions
- `package.json` `name` doesn't need to match manifest `id`
- Runtime identity is determined by manifest / entry export plugin id; verify with `openclaw plugins inspect <id>`

## Entry Point

### Recommended: `definePluginEntry`

```typescript
import { Type } from "@sinclair/typebox";
import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

export default definePluginEntry({
  id: "my-plugin",
  name: "My Plugin",
  description: "Adds a custom tool to OpenClaw",
  register(api) {
    api.registerTool({
      name: "my_tool",
      description: "Do a thing",
      parameters: Type.Object({
        input: Type.String()
      }),
      async execute(_toolCallId, params) {
        return {
          content: [{ type: "text", text: `Got: ${params.input}` }]
        };
      },
    });
  },
});
```

### Compatible Forms

```typescript
export default function register(api) {
  api.registerTool({ name: "my_tool", description: "..." });
}
```

Or:

```typescript
export default {
  id: "my-plugin",
  name: "My Plugin",
  register(api) {
    api.registerTool({ name: "my_tool", description: "..." });
  },
};
```

## Plugin API Capabilities

```typescript
api.registerProvider({ /* Model Provider */ });
api.registerChannel({ plugin: myChannelPlugin });
api.registerTool({ /* Agent tool */ });
api.registerHook("command:new", handler, { name: "..." });
api.registerSpeechProvider({ /* TTS / STT */ });
api.registerMediaUnderstandingProvider({ /* Image/audio analysis */ });
api.registerImageGenerationProvider({ /* Image generation */ });
api.registerWebSearchProvider({ /* Web search */ });
api.registerHttpRoute({ /* HTTP endpoint */ });
api.registerCommand({ /* Auto-reply command */ });
api.registerCli(({ program }) => { /* CLI */ });
api.registerContextEngine({ /* Context engine */ });
api.registerService({ /* Background service */ });
```

## Discovery and Priority

Default discovery order:

1. `plugins.load.paths`
2. `<workspace>/.openclaw/extensions/`
3. `~/.openclaw/extensions/`
4. `<openclaw>/extensions/`

On ID conflicts, higher priority wins.

## Configuration

```json5
{
  plugins: {
    enabled: true,
    allow: ["voice-call"],
    deny: ["untrusted"],
    load: { paths: ["~/dev/my-extension"] },
    entries: {
      "voice-call": {
        enabled: true,
        config: { provider: "twilio" },
      },
    },
    slots: {
      memory: "memory-core",
      contextEngine: "legacy",
    },
  },
}
```

## Compatible Bundles — Mapped Capabilities

### Supported

- Bundle skill roots → OpenClaw skills
- Claude `commands/` / Cursor `.cursor/commands/` → skill content
- Codex hook packs that match OpenClaw expectations
- `.mcp.json` supported stdio MCP configurations
- Claude `settings.json` partial defaults

### Detected Only, Not Executed

- Claude `agents`
- Claude / Cursor `hooks.json`
- Cursor `.cursor/agents`, `.cursor/rules`
- Other unmapped bundle metadata

## Management Commands

```bash
openclaw plugins list
openclaw plugins inspect <id>
openclaw plugins inspect <id> --json
openclaw plugins install @openclaw/voice-call
openclaw plugins install ./my-plugin
openclaw plugins install -l ./my-plugin
openclaw plugins install <plugin>@<marketplace>
openclaw plugins marketplace list <marketplace>
openclaw plugins update <id>
openclaw plugins update --all
openclaw plugins enable <id>
openclaw plugins disable <id>
openclaw plugins doctor
```

`info` still works but is now just an alias for `inspect`.

## Security

- Native plugins run inside Gateway process — treated as trusted code
- npm installs use `--ignore-scripts` by default
- Plugin install/update requires same review level as executing code
- `plugins.allow` should remain explicit allowlist

## Development Workflow

```bash
# 1. Create directory
mkdir my-plugin && cd my-plugin

# 2. Create manifest
cat > openclaw.plugin.json << 'EOF'
{
  "id": "my-plugin",
  "name": "My Plugin",
  "description": "What it does",
  "configSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {}
  }
}
EOF

# 3. Create package.json
cat > package.json << 'EOF'
{
  "name": "@myorg/openclaw-my-plugin",
  "version": "1.0.0",
  "type": "module",
  "openclaw": { "extensions": ["./index.ts"] }
}
EOF

# 4. Create root entry
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
      parameters: Type.Object({ query: Type.String() }),
      async execute(_toolCallId, params) {
        return { content: [{ type: "text", text: `Result: ${params.query}` }] };
      },
    });
  },
});
EOF

# 5. Link install and verify
openclaw plugins install -l .
openclaw plugins inspect my-plugin
```

## Import Convention

Import from specific subpaths only:

```typescript
import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";
import { createChatChannelPlugin } from "openclaw/plugin-sdk/channel-core";
import { defineSingleProviderPluginEntry } from "openclaw/plugin-sdk/core";
```

Full list of 200+ subpaths available in: `scripts/lib/plugin-sdk-entrypoints.json`
