# Contributing

## Setup
1. Install Xcode 26+.
2. Clone repository.
3. Run:
   - `scripts/dev/bootstrap.sh`
   - `scripts/dev/doctor.sh`
   - `scripts/dev/preflight.sh --package-only`

## Development Guidelines
- Keep canonical user data in the document store (`Sources/DocumentStore`).
- Do not introduce network dependencies for core features.
- Keep summary outputs derived and regenerable.
- Prefer additive schema migrations with explicit `schemaVersion`.

## Test Expectations
- Add/adjust unit tests for any change in:
  - domain models
  - date math
  - persistence/layout
  - summary generation
  - journal/timeline behavior
- Add integration tests for user-visible behavior changes.

## Issues and Requests
- Use GitHub issue forms for bug reports and feature requests.
- Include reproducible steps, impact, and environment details.

## Security Reports
- Do not disclose vulnerabilities in public issues.
- Follow the private reporting process in `.github/SECURITY.md`.

## PR Checklist
- [ ] Build passes (`scripts/dev/package-build.sh`)
- [ ] Tests pass (`scripts/dev/package-test.sh`)
- [ ] App builds pass (`scripts/dev/app-build-ios.sh` and `scripts/dev/app-build-maccatalyst.sh`)
- [ ] README/docs updated if behavior changed
- [ ] New fields are migration-safe
- [ ] No external server dependency introduced
