# Plugin Operations Management Guide

<!-- Updated: 2026-04-08 -->

Plugin lifecycle operations reference. For development/creation see `plugin-api.md` and `scaffold-plugin-guide.md`.

## Installation

### Install Sources and Recommended Scenarios

| Source | Command | Use Case |
|--------|---------|----------|
| Local path | `openclaw plugins install ./my-plugin` | Install native plugin or compatible bundle |
| Local link | `openclaw plugins install --link ./my-plugin` | Dev/debugging, code changes take effect immediately |
| npm / ClawHub package | `openclaw plugins install @org/name` | Third-party/official plugin, ClawHub first then npm |
| npm exact version | `openclaw plugins install @org/name --pin` | Lock version, avoid unexpected upgrades |
| Archive file | `openclaw plugins install ./plugin.tgz` | Offline deployment |
| Marketplace | `openclaw plugins install <plugin>@<marketplace>` | Claude marketplace / custom marketplace |

### ClawHub Integration

Install from ClawHub:
```bash
openclaw plugins install clawhub:<skill-name>
openclaw marketplace list clawhub
```

### Formats OpenClaw Auto-Detects

- Native OpenClaw plugins: `openclaw.plugin.json`
- Codex bundles: `.codex-plugin/plugin.json`
- Claude bundles: `.claude-plugin/plugin.json` or default Claude layout
- Cursor bundles: `.cursor-plugin/plugin.json`

### Install Sources

| Source Type | Example |
|-------------|---------|
| ClawHub | `clawhub:skill-name` |
| npm | `@org/package-name` |
| Local path | `./path/to/plugin` |
| GitHub shorthand | `owner/repo` |
| Git URL | `https://github.com/owner/repo` |
| Marketplace | `plugin@marketplace-name` |

### Post-Install Auto-Behavior

- Files installed to current state dir's `extensions/` root (default `~/.openclaw/extensions/`)
- Writes to `openclaw.json` `plugins.installs` record
- If `plugins.allow` exists and doesn't include the plugin → may stay disabled
- `openclaw plugins inspect <id>` to check `Format: openclaw` or `Format: bundle`

### Bundle Capability Detection

OpenClaw detects bundle format and maps supported capabilities:
- `.codex-plugin/` → Codex bundle
- `.claude-plugin/` → Claude bundle
- `.cursor-plugin/` → Cursor bundle
- Each mapped to appropriate OpenClaw capability

### Common Install Issues

| Symptom | Cause | Fix |
|---------|--------|-----|
| `plugin path not found` | Path doesn't exist (e.g., `/tmp` cleaned) | Re-install to persistent path |
| `not in allowlist` | `plugins.allow` whitelist doesn't include it | `openclaw plugins enable <id>` |
| `loaded without install/load-path provenance` | Non-standard install flow | Reinstall with `openclaw plugins install` |
| `plugin manifest requires configSchema` | Native manifest missing `configSchema` | Add empty schema or real schema |
| `extension entry escapes package directory` | Entry escapes package directory | Adjust entry to specific file within package |
| Shows `Format: bundle` | Source is Claude/Codex/Cursor bundle | Verify supported mapped capabilities, don't expect native manifest |

### Flags

| Flag | Purpose |
|------|---------|
| `--force` | Force reinstall/overwrite |
| `--pin` | Pin to exact version |
| `--link` | Create symlink instead of copy |
| `--dangerously-force-unsafe-install` | Skip safety checks (use with caution) |

### Remote Gateway Install

```bash
# npm / ClawHub package — remote direct install
ssh user@host "openclaw plugins install @org/plugin-name"

# Local files — first transfer then install
scp -r ./my-plugin user@host:~/tmp/my-plugin
ssh user@host "openclaw plugins install ~/tmp/my-plugin"
```

> **Avoid `/tmp` persistence dependency**: macOS `/tmp` gets periodically cleaned by system. During development prefer `--link` to point to persistent directory, use formal install for production.

## Uninstall

```bash
openclaw plugins uninstall <id>
openclaw plugins uninstall <id> --dry-run
openclaw plugins uninstall <id> --keep-files
```

Uninstall will:
1. Remove install record from `plugins.installs`
2. Remove from `plugins.allow` (if exists)
3. Remove config from `plugins.entries`
4. Delete installed files (unless `--keep-files`)
5. For active memory plugin, fallback slot to `memory-core`

## Update

```bash
openclaw plugins update <id>
openclaw plugins update <id> --dry-run
openclaw plugins update --all
openclaw plugins update @openclaw/voice-call@beta
```

- Updates depend on tracked install in `plugins.installs`
- For npm installs, can pass explicit spec to override update source
- Plugins installed from local path need manual file updates

## Enable / Disable

```bash
openclaw plugins enable <id>
openclaw plugins disable <id>
```

Confirm after enable/disable:

```bash
openclaw plugins list
openclaw plugins inspect <id>
```

## Inspect / Diagnostics

```bash
openclaw plugins inspect <id>
openclaw plugins inspect <id> --json
openclaw plugins doctor
openclaw plugins marketplace list <marketplace>
```

`info` still works but is just an alias for `inspect`.

## Config Structure Quick Reference

```json5
{
  plugins: {
    enabled: true,
    allow: ["huginn", "postiz"],
    deny: [],
    load: {
      paths: ["~/path/to/plugin"]
    },
    entries: {
      "huginn": {
        enabled: true,
        config: {
          huginnUrl: "http://host:3000"
        }
      }
    },
    installs: {
      "huginn": {
        source: "path",
        installPath: "~/.openclaw/extensions/huginn",
        version: "1.0.0",
        installedAt: "2026-03-10T08:51:44.289Z"
      }
    },
    slots: {
      memory: "memory-core",
      contextEngine: "legacy"
    }
  }
}
```

## Security Notes

- Native plugin runs inside Gateway process, treated as "execute trusted code"
- npm install automatically uses `--ignore-scripts`
- `plugins.allow` should always be explicitly configured
- Plugins from bundle / marketplace should also be evaluated with same code review intensity
