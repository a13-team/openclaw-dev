# OpenClaw Setup Questionnaire

Use this checklist before writing or rewriting `~/.openclaw/openclaw.json`.

## 1. Host and runtime

- Operating system and version.
- Local machine, WSL2, VPS, or remote gateway.
- Whether OpenClaw is already installed.
- Whether the gateway should run as a daemon/service.

## 2. Trust boundary

- Single operator or multiple trusted users.
- Private LAN only, Tailscale, SSH tunnel, reverse proxy, or public internet.
- Whether inbound chat access must be restricted to pairing/allowlist.

## 3. Channels and control surfaces

- Which surfaces must work on day one:
  - WebChat / Control UI
  - Telegram
  - Signal
  - WhatsApp
  - Discord
  - other
- Which surface is the main operator console.
- Which surfaces are notification-only.

## 4. Models, providers, and cost

- Primary provider and model.
- Required fallback provider and model.
- Auth style for each provider: API key, OAuth, token exchange, local gateway, or SecretRef-backed environment variable.
- Budget ceiling or low-cost mode requirement.
- Need for coding-specialized routing.
- Need for search, media, browser, voice, or image providers.
- Whether the operator wants QuickStart defaults first or full Advanced control during onboarding.

## 5. Agent topology

- Master/orchestrator agent name.
- Specialist agents required.
- Role of each specialist.
- Which agents may delegate to which others.
- Separate workspaces required or not.

## 6. Memory and autonomy

- Built-in memory only, or external memory engine.
- Heartbeat needed or not.
- Cron jobs needed or not.
- Hooks/standing orders/task flow needed or not.
- Backup and retention expectations.

## 7. Skills and plugins

- Must-have capabilities to install from ClawHub.
- Repo-local skills that should be enabled.
- Missing capabilities that should become new skills.
- Whether third-party skills/plugins are allowed after review only.

## 8. Secrets and credentials

- Which tokens/keys are already available.
- Where they will be stored.
- Which credentials the agent may configure automatically.
- Which credentials must be pasted or approved manually.

## 9. Access policy and approval boundaries

- Default DM policy: pairing, allowlist, open, or disabled.
- Group policy: allowlist, open, or disabled.
- Whether group chats must require mentions.
- Whether the agent may install missing binaries/packages automatically.
- Whether the agent may restart services/daemons automatically during repair.

## Completion rule

Do not start configuration writes until these decisions are either:

- answered by the user
- discovered from the current machine state
- or explicitly assumed and stated back to the user

If assumptions are necessary, make the safest reversible ones.
