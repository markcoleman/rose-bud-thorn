# GitHub Branch Protection Checklist

Apply these settings to `main` in GitHub repository settings.

## Branch Rule
- Rule target: `main`
- Require a pull request before merging: enabled
- Required approving reviews: at least 1
- Dismiss stale approvals on new commits: enabled
- Require review from Code Owners: enabled
- Require conversation resolution before merge: enabled

## Required Status Checks
Enable "Require status checks to pass before merging" and include only always-on checks:
- `Review dependency diffs`

Do not set Apple CI checks as globally required while `.github/workflows/apple-ci.yml` is path-filtered at the workflow trigger level. For non-code PRs, those checks are skipped and no status contexts are created.

Current Apple CI check names (useful for PR evidence and workflow-change reviews):
- `Swift package build + test`
- `Build app (iOS)`
- `Build app (Mac Catalyst)`
- `UI smoke test`

## Safety Settings
- Require branches to be up to date before merging: enabled
- Block force pushes: enabled
- Block branch deletion: enabled

## Merge Policy
- Allow squash merges: enabled
- Allow merge commits: disabled
- Allow rebase merges: disabled
- Automatically delete head branches: enabled

## Verification Commands
Run in the repository root to cross-check workflow job names:

```bash
rg -n "name: Swift package build \\+ test|name: Build app \\(\\$\\{\\{ matrix.lane \\}\\}\\)|name: UI smoke test|name: Review dependency diffs" .github/workflows
```
