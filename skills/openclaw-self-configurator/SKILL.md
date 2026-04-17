---
name: openclaw-self-configurator
description: "Use this skill when an OpenClaw target state is already defined and must be turned into a concrete self-configuration rollout pack: topology blueprint, config skeleton guidance, skill install plan, validation matrix, repair paths, and go-live checklist."
metadata: {"clawdbot":{"always":false,"emoji":"🛠️"}}
user-invocable: true
version: 1.0.0
---

# OpenClaw Self-Configurator

Turn an approved OpenClaw target state into concrete operator-facing setup artifacts without inventing hidden steps.

> Non-negotiable:
> - Start only after discovery and target-state design are complete.
> - Produce concrete rollout artifacts, not vague suggestions.
> - Reuse repo-local skills before recommending external installs.
> - Every recommendation must map to a validation or repair step.

Mandatory reference pack for this skill:

- `references/self-config-blueprint.md`
- `references/self-config-checklist.md`
- `references/recommended-skill-packs.md`
- `../clawhub-skill-installer/SKILL.md` when external skills are needed
- `../openclaw-skill-development/SKILL.md` when a required capability still has no matching skill

## Mission

Given an approved target state, assemble a self-configuration rollout pack that an operator or orchestrator agent can execute and verify.

The rollout pack should cover:

- control surfaces and trust boundaries
- agent topology and delegation rules
- config skeleton guidance
- skill reuse versus install decisions
- validation sequence
- repair paths for likely failures

## Phase 1: Normalize Inputs

Before generating anything, confirm these inputs are explicit:

1. host/runtime choice
2. primary and fallback control surfaces
3. provider and model routing choices
4. master/specialist topology
5. memory and automation posture
6. skill strategy
7. security boundaries

If any of these are still ambiguous, hand control back to `openclaw-autonomous-setup` rather than guessing.

## Phase 2: Produce the Rollout Pack

Generate a compact operator pack with these sections:

1. **Topology blueprint**
   - master agent
   - named specialists
   - delegation allowlist
   - bounded concurrency/depth assumptions

2. **Config skeleton guidance**
   - which `openclaw.json` areas change
   - which values must come from env/secrets
   - which values stay conservative by default

3. **Skill plan**
   - repo-local skills to reuse
   - external skills to search/install
   - new skills that must be authored if reuse fails

4. **Validation matrix**
   - what to run after each setup batch
   - what good output looks like
   - what counts as a blocker

5. **Repair playbook**
   - missing binary
   - malformed config
   - channel pairing failure
   - provider auth failure
   - skill install/eligibility failure
   - QA/validator drift

6. **Go-live checklist**
   - final smoke tests
   - remaining manual steps
   - residual risks

## Phase 3: Keep Output Practical

When generating the rollout pack:

- prefer bulletproof defaults over aspirational complexity
- separate "required now" from "optional later"
- keep community tooling as a recommendation, not a hidden prerequisite
- make every external dependency explicit

Do not claim the system is self-healing unless the validation and repair loop is actually named and testable.

## Phase 4: Finish With Validation Routing

Every run should finish by routing the operator to:

- `commands/validate-autonomous-setup.md` for bundle/workflow integrity
- `plugins/qa/scripts/run-qa-tests.sh --quick` for repo-level QA quick mode
- `plugins/qa/scripts/run-qa-tests.sh --full` only when deeper checks are justified

If no suitable installable skill exists for a required capability, switch to `openclaw-skill-development` and create it as a reusable bundle.
