# OpenClaw Plugin Development Patterns and Troubleshooting

<!-- Updated: 2026-04-08 -->

## Plugin Development Patterns

### Minimal Tool Plugin

```typescript
import { Type } from "@sinclair/typebox";
import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

// openclaw.plugin.json needs at minimum:
// { "id": "my-tool", "configSchema": { "type": "object", "additionalProperties": false, "properties": {} } }

export default definePluginEntry({
  id: "my-tool",
  name: "My Tool",
  description: "Translate text between languages",
  register(api) {
    api.registerTool({
      name: "translate",
      description: "Translate text between languages",
      parameters: Type.Object({
        text: Type.String({ description: "Text to translate" }),
        targetLang: Type.String({ description: "Target language code" }),
      }),
      async execute(_toolCallId, params) {
        const result = await callTranslateAPI(params.text, params.targetLang);
        return { content: [{ type: "text", text: result }] };
      },
    });
  },
});
```

### Channel Plugin Structure

```typescript
import { definePluginEntry } from "openclaw/plugin-sdk/channel-core";

export default definePluginEntry({
  id: "mychannel",
  name: "MyChannel",
  description: "Channel integration",
  register(api) {
    api.registerChannel({
      plugin: createChatChannelPlugin({
        id: "mychannel",
        name: "MyChannel",
        // ... channel configuration
      }),
    });
  },
});
```

### Provider Plugin Structure

```typescript
import { defineSingleProviderPluginEntry } from "openclaw/plugin-sdk/core";

export default defineSingleProviderPluginEntry({
  id: "my-provider",
  name: "My Provider",
  description: "Custom model provider",
  register(api) {
    api.registerProvider({
      id: "my-provider",
      apiKey: process.env.MY_PROVIDER_API_KEY,
      // ... provider configuration
    });
  },
});
```

### Channel Onboarding Hook Pattern

```typescript
import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

export default definePluginEntry({
  id: "mychannel",
  name: "MyChannel",
  description: "Channel integration",
  register(api) {
    api.registerChannel({ plugin: myChannelPlugin });

    api.registerHook("gateway:startup", async () => {
      const cfg = api.config;
      const accounts = cfg.channels?.mychannel?.accounts ?? {};
      for (const [id, account] of Object.entries(accounts)) {
        if (account.enabled !== false) {
          await initializeAccount(id, account);
        }
      }
    }, { name: "mychannel.startup", description: "Initialize channel accounts" });
  },
});
```

### Multi-Feature Plugin (Tool + Hook + CLI)

```typescript
import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

export default definePluginEntry({
  id: "my-plugin",
  name: "My Plugin",
  description: "Tool + hook + cli example",
  register(api) {
    api.registerTool({ name: "my_tool", description: "..." });

    api.registerHook("command:new", async (event) => {
      api.logger.info(`Session reset: ${event.sessionKey}`);
    }, { name: "my-plugin.session-log" });

    api.registerCli(({ program }) => {
      program.command("mystatus")
        .description("Show plugin status")
        .action(() => console.log("OK"));
    }, { commands: ["mystatus"] });

    api.registerCommand({
      name: "ping",
      description: "Responds with pong",
      handler: () => ({ text: "pong" }),
    });
  },
});
```

### Bundle Compatibility

OpenClaw recognizes these bundle formats:

#### Claude Bundle Structure
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

#### Codex Bundle Structure
```text
my-bundle/
├── .codex-plugin/
│   └── plugin.json
├── skills/
├── hooks/
├── .mcp.json
└── .app.json
```

#### Cursor Bundle Structure
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

### Skills Shipping via Plugin Manifest

```json
{
  "id": "my-plugin",
  "name": "My Plugin",
  "skills": [
    {
      "name": "plugin-skill",
      "dir": "./skills/plugin-skill"
    }
  ],
  "configSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {}
  }
}
```

---

## Troubleshooting

### Plugin Not Loading

| Symptom | Cause | Fix |
|---------|--------|-----|
| Not visible in `plugins list` | Path not in discovery scope | Check `plugins.load.paths` or use `openclaw plugins install` |
| Shows but disabled | Default disabled / allowlist not approved | `openclaw plugins enable <id>` |
| Shows but has error | Load exception | `openclaw plugins doctor`, check Gateway logs |
| Shows as `Format: bundle` | Installed as Claude/Codex/Cursor bundle | Only verify supported mapped capabilities, don't check for native manifest |
| ID conflict | Multiple plugins with same ID | Higher priority path wins, check discovery order |

### Common Install Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `extension entry escapes package directory` | `openclaw.extensions` points to directory or escapes package | Change to specific file within package, e.g., `["./index.ts"]` |
| `plugin manifest requires configSchema` | Manifest missing `configSchema` | Add empty schema or real schema |
| `package.json missing openclaw.extensions` | Missing `openclaw` field | Add `"openclaw": {"extensions": ["./index.ts"]}` |
| `extracted package missing package.json` | No `package.json` in directory | Create `package.json` and declare `openclaw.extensions` |
| `plugin already exists` | Plugin with same ID already exists | Uninstall old version first or clean old install records |
| `loaded without install/load-path provenance` | Non-standard install flow | Reinstall with `openclaw plugins install` |

### Verified Install Workflow

```bash
# Native plugin / compatible bundle — same install surface
openclaw plugins install -l /path/to/my-plugin   # Dev mode
openclaw plugins install /path/to/my-plugin      # Copy install

# Check recognition result
openclaw plugins inspect my-plugin
openclaw plugins inspect my-plugin --json
```

### Entry Point Issues

```bash
# Check TypeScript syntax
npx tsc --noEmit index.ts

# Check default export
node -e "import('./index.ts').then(m => console.log(typeof m.default))"
```

### Dependency Issues

```bash
# OpenClaw uses --ignore-scripts
npm install --ignore-scripts
```

### Channel Plugin Debug

```bash
openclaw channels status --probe
jq '.channels.<id>' ~/.openclaw/openclaw.json
openclaw gateway --verbose
```

### Config Issues

```bash
jq '.plugins' ~/.openclaw/openclaw.json
jq '.plugins.slots' ~/.openclaw/openclaw.json
```
