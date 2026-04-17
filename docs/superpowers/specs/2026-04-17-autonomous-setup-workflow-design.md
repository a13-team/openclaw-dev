# Autonomous Setup Workflow Design

**Date:** 2026-04-17

## Goal

Turn the repository's in-progress autonomous setup material into a complete, internally consistent workflow that an operator can discover, run, validate, and repair from the bundle itself.

## Context

The repository already contains:

- `skills/openclaw-autonomous-setup`
- `skills/clawhub-skill-installer`
- Copilot prompt and instruction files for autonomous setup
- README copy describing autonomous setup as a supported outcome

The current gap is that this material is not yet a coherent workflow. In particular:

- there is no dedicated execution-layer self-configuration skill
- there is no user-facing command that clearly starts the full autonomous setup flow
- there is no user-facing command dedicated to validating that workflow
- the QA module documents a shared `run-qa-tests.sh` entrypoint, but the script is missing
- docs, skills, and QA references are at risk of drifting independently

## Desired Outcome

After this change, the repository should present a complete autonomous setup operator pack with:

1. a clear entry command for full setup guidance
2. a dedicated execution/self-configuration skill layer
3. a narrow validation command and script for workflow integrity
4. a working canonical QA runner entrypoint
5. synchronized documentation across README, bundle instructions, and prompts

## Design

### 1. Workflow Layers

Keep autonomous setup split into two layers:

- `openclaw-autonomous-setup`
  This remains the orchestration and decision-making layer. It owns discovery, target-state design, safe sequencing, and repair policy.
- `openclaw-self-configurator`
  This becomes the execution layer. It turns an approved target state into practical setup artifacts and rollout guidance: self-config checklist, topology blueprint, recommended skill packs, config skeleton guidance, validation matrix, and repair playbook.

This separation avoids overloading the orchestration skill while keeping the implementation guidance reusable.

### 2. User Entry Points

Add two user-facing commands:

- `commands/setup-autonomous.md`
  The primary entrypoint for the full autonomous setup workflow. It should route the user through discovery, target-state definition, setup execution guidance, and post-change validation.
- `commands/validate-autonomous-setup.md`
  A narrow integrity-check command for the workflow itself. It should invoke a dedicated validation script rather than relying on broad runtime assumptions.

These commands should reference the same skills and validation surfaces named in the docs.

### 3. Validation Model

Introduce a narrow validation script:

- `scripts/validate-autonomous-setup.sh`

This validator should be intentionally lightweight and deterministic. It should check:

- required files exist
- skill references point to existing files
- README and GitHub instruction surfaces mention the same autonomous setup entrypoints
- the QA module has a canonical runnable script
- the relevant skills pass `scripts/skill-lint.sh`

This script should not require a live OpenClaw installation by default. The goal is bundle integrity, not deployment health.

### 4. QA Canonical Runner

Restore the missing QA entrypoint:

- `plugins/qa/scripts/run-qa-tests.sh`

It should support at least:

- `--quick`
  Static workflow checks suitable for repo-level regression and documentation consistency
- `--full`
  The same baseline checks plus best-effort runtime checks only when the relevant binaries or environment are available

This script becomes the canonical target already referenced by root docs, QA docs, commands, and wrappers.

### 5. Documentation Strategy

Documentation should be layered rather than duplicated.

- `README.md`
  High-level entry route and operator-facing workflow summary
- `skills/openclaw-autonomous-setup/references/openclaw-setup-research.md`
  Expanded high-signal setup research
- `skills/openclaw-self-configurator/references/self-config-blueprint.md`
  Practical self-configuration architecture distilled from the external research
- `skills/openclaw-self-configurator/references/self-config-checklist.md`
  Pre-flight, rollout, validation, and go-live checklist
- `skills/openclaw-self-configurator/references/recommended-skill-packs.md`
  Recommended external/community skill packs and how they fit into the setup workflow

This keeps the top-level docs concise while preserving practical detail.

### 6. Self-Improvement Rules

The workflow should apply self-improvement as disciplined engineering rather than magic behavior.

Validation and QA should explicitly classify failures into a few useful categories:

- missing file / broken reference
- stale documentation or command wiring
- QA entrypoint drift
- skill lint failure
- optional runtime prerequisite unavailable

Each category should produce a clear repair hint.

## File Plan

### New files

- `docs/superpowers/specs/2026-04-17-autonomous-setup-workflow-design.md`
- `docs/superpowers/plans/2026-04-17-autonomous-setup-workflow.md`
- `skills/openclaw-self-configurator/SKILL.md`
- `skills/openclaw-self-configurator/references/self-config-blueprint.md`
- `skills/openclaw-self-configurator/references/self-config-checklist.md`
- `skills/openclaw-self-configurator/references/recommended-skill-packs.md`
- `commands/setup-autonomous.md`
- `commands/validate-autonomous-setup.md`
- `scripts/validate-autonomous-setup.sh`
- `plugins/qa/scripts/run-qa-tests.sh`
- `tests/autonomous-setup-workflow.sh`

### Modified files

- `README.md`
- `skills/openclaw-autonomous-setup/SKILL.md`
- `skills/openclaw-autonomous-setup/references/openclaw-setup-research.md`
- `.github/copilot-instructions.md`
- `.github/prompts/openclaw-autonomous-setup.prompt.md`
- `.github/instructions/openclaw-autonomy.instructions.md`
- `plugins/qa/AGENTS.md`
- `plugins/qa/scripts/codex-diagnose.sh` if alignment changes are needed

## Testing Strategy

Use a minimal shell-based regression path:

1. Add a test script that fails while the canonical QA runner and autonomous validation surfaces are missing or inconsistent.
2. Run the test to confirm failure.
3. Implement the missing workflow files and wiring.
4. Re-run the targeted test until it passes.
5. Run `scripts/skill-lint.sh` against the affected skills.
6. Run the new validation command/script and QA quick mode.

This keeps verification focused and compatible with the repository's existing shell-centric tooling.

## Risks

- The repo already has unrelated local changes in shared files like `README.md` and plugin manifests. Edits must stay surgical.
- The QA module currently documents behavior that does not exist. Fixes should restore the documented contract, not invent a new incompatible one.
- Autonomous setup content can easily become overlong. The new execution-layer skill must keep its main body concise and move detail into references.

## Implementation Boundary

This iteration should complete the repository workflow and QA integrity. It should not attempt to build a live OpenClaw installer, daemon manager, or native plugin runtime beyond the existing bundle scope.
