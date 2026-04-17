# OpenClaw Self-Configuration Checklist

## Pre-flight

- confirm the host/runtime target
- confirm primary and fallback control surfaces
- confirm provider and fallback model
- confirm topology and delegation boundaries
- confirm where secrets and tokens will live
- confirm which skills should be reused, installed, or authored

## Rollout

- run or guide `openclaw onboard` first on clean installs
- validate browser/control UI before chat channels
- add Telegram before higher-friction channels unless privacy requires otherwise
- apply topology and delegation limits before broader automation
- install only the skills that the approved target state actually needs

## Validation

- run `validate-autonomous-setup`
- run `plugins/qa/scripts/run-qa-tests.sh --quick`
- verify relevant skills with `scripts/skill-lint.sh`
- verify the final operator route is documented in README and GitHub instruction surfaces

## Repair

- missing file or broken reference: restore the file or fix the pointer
- stale docs: align README, prompts, and instructions to the real entrypoints
- missing QA runner: restore `plugins/qa/scripts/run-qa-tests.sh`
- skill lint failure: reduce body bloat, fix frontmatter, or restore references
- runtime prerequisite missing: report as optional blocker unless the task requires it

## Go-live

- browser/control UI path verified
- at least one operator chat path verified or explicitly deferred
- topology documented
- validation route documented
- remaining manual steps listed for the operator
