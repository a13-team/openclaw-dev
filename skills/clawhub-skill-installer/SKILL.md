---
name: clawhub-skill-installer
description: "Use this skill when asked to find, install, update, audit, or repair OpenClaw skills from ClawHub or the active workspace; when the user names a capability and expects the agent to fetch the right skill automatically; or when a skill install failed and must be diagnosed, retried, validated, or replaced with a newly authored skill."
metadata: {"clawdbot":{"always":false,"emoji":"📦"}}
user-invocable: true
version: 1.0.0
---

# ClawHub Skill Installer

Install or repair OpenClaw skills without making the operator manually hunt through the registry.

> Non-negotiable:
> - Reuse an existing local or bundled skill before pulling a new one.
> - Prefer `openclaw skills search/install/update` for normal installs.
> - Use the separate `clawhub` CLI only when the task is about publish, registry auth, or sync.
> - Validate the installed skill before declaring success.

## Phase 0: Clarify the target capability

Before installation, capture:

1. the capability or tool name the operator wants
2. the target agent or workspace
3. whether version pinning or only-reviewed third-party installs are required
4. whether the install should be global/shared or workspace-local

If the user only gives a rough need such as "GitHub skill" or "install telegram tooling", that is enough to start search.

## Phase 1: Inspect what already exists

Run the narrowest checks first:

```bash
openclaw skills list --verbose
openclaw skills list --eligible
```

If the needed capability already exists locally, prefer enabling or reusing it instead of installing another copy.

## Phase 2: Search intelligently

Search by intent first, not by guessed slug:

```bash
openclaw skills search "<capability-name>"
openclaw skills search "<tool-name>"
```

Selection rules:

- prefer the closest semantic match to the requested capability
- prefer maintained, clearly described skills over vague ones
- prefer the least surprising option when multiple skills overlap
- if nothing is a strong match, do not install a random near-miss

## Phase 3: Install or update

Normal install flow:

```bash
openclaw skills install <skill-slug>
```

Update flow:

```bash
openclaw skills update <skill-slug>
openclaw skills update --all
```

Registry-specific flow, only when the task actually requires it:

```bash
clawhub install <skill-slug>
clawhub update <skill-slug>
```

## Phase 4: Validate the install

Run checks that prove the skill is real and eligible:

```bash
openclaw skills list --verbose
openclaw skills list --eligible
openclaw doctor
```

Then verify one of the following:

- the skill appears in the intended workspace or shared skill path
- the skill is eligible on the current machine
- a new session can trigger it

## Phase 5: Repair failures

If installation or loading fails:

1. capture the exact error
2. inspect whether the skill has missing binary or environment requirements
3. run `openclaw doctor`
4. retry the install or update
5. if the skill is broken beyond quick repair, choose another candidate or author a new skill

Common repair actions:

- install a missing binary required by the skill
- switch from a bad candidate to a better-matched skill
- update the skill to the latest version
- remove duplicate/conflicting local copies if precedence is wrong

## Phase 6: Fall back to authoring

If search results are weak or the right capability does not exist, stop guessing and switch to `openclaw-skill-development`.

Minimum expectation:

- create `skills/<skill-name>/SKILL.md`
- add YAML frontmatter
- include supporting `scripts/` only when reusable code is needed
- validate before treating it as installed

## Final deliverable

End with a short operator report:

- requested capability
- selected skill slug or reason no skill matched
- target workspace/agent
- validation evidence
- follow-up action if a new skill still needs to be authored
