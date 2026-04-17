# OpenClaw Self-Configuration Blueprint

This blueprint distills the repository's autonomous setup research into the concrete layers needed for a reusable self-configuration workflow.

## Layer 1: Discovery and approval

Handled by `openclaw-autonomous-setup`.

Required outputs:

- approved control surfaces
- approved provider/model matrix
- approved topology
- approved security boundaries
- approved skill strategy

No execution-layer artifact should be produced before these are explicit.

## Layer 2: Execution-layer rollout pack

Handled by `openclaw-self-configurator`.

Required artifacts:

- topology blueprint
- config skeleton guidance
- skill install or authoring plan
- validation matrix
- repair playbook
- go-live checklist

## Recommended topology baseline

- `orchestrator` as the user-facing master agent
- `research` for docs and external facts
- `builder` for code, scripts, and config generation
- `verifier` for tests and regressions
- `ops` for gateway, channels, logs, and deployment surfaces

Default policy:

- explicit delegation allowlists
- `maxSpawnDepth: 1`
- narrow specialist roles
- one primary control surface plus one fallback

## Recommended security baseline

- WebChat/Control UI for the first smoke test
- Telegram as the usual day-to-day operator channel
- Signal only when privacy needs justify `signal-cli`
- pairing or allowlists by default
- secrets stored in env or secret files, never in committed bundle docs

## Validation baseline

The workflow should always be able to answer:

- what changed
- how it was validated
- what failed
- how the operator should repair or continue

Repo-level validation surfaces:

- `commands/validate-autonomous-setup.md`
- `scripts/validate-autonomous-setup.sh`
- `plugins/qa/scripts/run-qa-tests.sh --quick`

## Anti-patterns

Avoid:

- pretending the repo can fully configure a live OpenClaw runtime without environment discovery
- coupling the workflow to one provider or one community package
- burying repair guidance inside large research documents
- calling the bundle "autonomous" when its own validation wiring is broken
