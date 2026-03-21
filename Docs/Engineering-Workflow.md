# Engineering Workflow

## Branching Convention
- Use short-lived branches from `main`.
- Preferred branch prefixes:
  - `codex/<topic>` for automation-driven work.
  - `feat/<topic>` for feature work.
  - `fix/<topic>` for defect fixes.

## Incremental Delivery Contract
- Split large changes into small, reviewable commits.
- Each commit should represent one bounded step in the plan.
- Do not start the next step until the current step validation passes.
- Include validation commands and outcomes in every commit message body.

## Local Validation Policy
- Baseline package checks:
  - `scripts/dev/package-build.sh`
  - `scripts/dev/package-test.sh`
- App build checks (run when app or CI build logic changes):
  - `scripts/dev/app-build-ios.sh`
  - `scripts/dev/app-build-maccatalyst.sh`
- UI smoke check (run when UI test lane logic changes):
  - `scripts/dev/ui-smoke.sh`
- Optional local pre-push guardrail:
  - `scripts/dev/install-hooks.sh` installs `.githooks/pre-push`
  - Set `RBT_SKIP_PRE_PUSH=1` to skip once when needed

## Pull Request Expectations
- Fill in the PR template with:
  - step traceability
  - validation evidence
  - required-check mapping
- Keep PRs scoped to the incremental step being proposed.
- Update docs when command surfaces, workflows, or contribution policy change.

## CI Check Names
The branch protection required-check names should match these workflow job names:
- `package-test`
- `build-app (iOS)`
- `build-app (Mac Catalyst)`
- `ui-smoke`
- `dependency-review`
