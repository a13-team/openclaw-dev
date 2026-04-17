# OpenClaw Autonomous Setup Target State

This is the end-state the setup agent should aim for unless the operator asks for a narrower configuration.

## 1. Control surfaces

- Control UI / WebChat works first. This is the zero-friction smoke test after onboarding.
- Telegram is the default operator chat channel for day-to-day control.
- Signal is optional and only enabled when the operator accepts `signal-cli` setup and maintenance.
- Remote access is explicit: Tailscale, SSH tunnel, or another approved path. No accidental public exposure.

## 2. Providers and model routing

- One strong primary model/provider is configured for the main agent.
- At least one fallback model/provider exists when uptime matters.
- Coding-heavy work is routed to the strongest coding-capable model available.
- Search, media, browser, and voice providers are configured only when they are actually required.
- Secrets are stored outside committed files and prompts, ideally through environment-backed refs or secret files.

## 3. Agent topology

- One master/orchestrator agent owns user interaction and task planning.
- Specialist agents stay narrow and observable. Recommended baseline:
  - `research`: docs, web, competitor, or integration discovery
  - `builder`: code changes, scripts, config generation
  - `verifier`: tests, checks, regression confirmation
  - `ops`: gateway, channels, logs, deployment, remote access
- `allowAgents` is explicit. The master can only delegate to named specialists.
- `maxSpawnDepth` stays `1` by default. Raise it to `2` only when the operator explicitly wants an orchestrator sub-agent that can spawn worker children.
- `maxConcurrent` and `runTimeoutSeconds` are tuned to the host rather than left implicit.

## 4. Skills and extensibility

- Existing repo-local skills are reused first.
- External skills are installed through `openclaw skills search/install/update`.
- The separate `clawhub` CLI is reserved for publish, sync, auth, or registry-specific workflows.
- If no suitable skill exists, the agent creates a new reusable skill with:
  - `skills/<skill-name>/SKILL.md`
  - YAML frontmatter
  - optional `scripts/` only when code improves repeatability
  - optional `references/` only when large supporting docs are needed

## 5. Memory and automation

- Built-in memory is acceptable for a minimal rollout; external memory is chosen intentionally, not by default.
- Heartbeat covers routine status awareness.
- Cron handles exact schedules.
- Hooks handle event-driven actions.
- Standing orders capture long-lived rules.
- Task flow is used for orchestrated multi-step jobs.

## 6. Security and trust boundaries

- DM access defaults to `pairing` or `allowlist`, not `open`.
- Group chats are allowlisted and mention-gated unless the operator explicitly wants a looser policy.
- Channel credentials, provider keys, and gateway auth stay out of version control.
- Service restarts, package installs, and binary provisioning are only done within the operator's stated approval boundary.

## 7. Validation and self-healing

The setup is not complete until these pass:

- `openclaw doctor`
- `openclaw health`
- `openclaw status --deep --all`
- `openclaw channels status --probe`
- provider/model status checks
- pairing checks for enabled channels
- skill listing and eligibility checks
- evidence that the master agent can only delegate to approved specialists

If a step fails, the agent:

1. captures the exact command, error, and relevant config fragment
2. diagnoses the failing subsystem
3. applies the smallest fix
4. reruns the failed step
5. keeps iterating until the layer works or an external blocker remains

## 8. Capabilities after setup

After a successful run, OpenClaw should be able to:

- accept operator control from browser and at least one chat surface
- route work through a master agent plus specialist agents
- install new capabilities from ClawHub by capability name, not just by memorized slug
- validate and self-heal its own channels, providers, and task surfaces after configuration changes
- recover from common setup errors by repairing config, reinstalling skills, or fixing missing dependencies
- create a new skill autonomously when no installed skill covers the task

## 9. What the operator should receive

Every full setup run should end with:

- what was installed or changed
- which control surfaces and models were verified
- which skills were installed or created
- which manual steps still require the operator
- what residual risks or assumptions remain
