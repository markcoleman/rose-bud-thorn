# Contributing

## Setup
1. Install Xcode 26+.
2. Clone repository.
3. Run:
   - `swift build`
   - `swift test`

## Development Guidelines
- Keep canonical user data in the document store (`Sources/DocumentStore`).
- Do not introduce network dependencies for core features.
- Keep summary/index outputs derived and regenerable.
- Prefer additive schema migrations with explicit `schemaVersion`.

## Test Expectations
- Add/adjust unit tests for any change in:
  - domain models
  - date math
  - persistence/layout
  - search behavior
  - summary generation
- Add integration tests for user-visible behavior changes.

## PR Checklist
- [ ] Build passes (`swift build`)
- [ ] Tests pass (`swift test`)
- [ ] README/docs updated if behavior changed
- [ ] New fields are migration-safe
- [ ] No external server dependency introduced
