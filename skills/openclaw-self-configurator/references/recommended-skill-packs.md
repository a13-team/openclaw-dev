# Recommended Skill Packs

These are research-backed candidates for a richer OpenClaw setup. Treat them as optional extensions, not silent prerequisites.

## Pack 1: Core autonomous setup

- `openclaw-autonomous-setup`
- `openclaw-self-configurator`
- `clawhub-skill-installer`

Use this pack to drive discovery, rollout-pack generation, and skill reuse/install decisions inside this repository.

## Pack 2: External setup acceleration

Use external/community packages only when the operator explicitly wants a broader OpenClaw environment beyond this bundle.

Examples referenced by the research material:

- MetaClaw-style setup generators
- maintenance/reference packs such as OpenClaw-Skill
- self-improvement loops
- workflow and multi-agent templates

Selection rule:

- prefer the smallest package that solves the approved need
- document why it is needed
- add a validation or rollback path

## Pack 3: Author when reuse fails

If no candidate skill is a strong match:

- stop guessing
- create a repo-local skill
- validate it with `scripts/skill-lint.sh`
- route future users through the new local skill instead of repeating manual steps

## Recommendation order

1. reuse local skills already in this bundle
2. search/install a clearly matching external skill
3. author a new local skill when the match is weak or operationally risky
