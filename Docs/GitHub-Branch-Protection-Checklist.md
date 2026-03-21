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
Enable "Require status checks to pass before merging" and include:
- `package-test`
- `build-app (iOS)`
- `build-app (Mac Catalyst)`
- `ui-smoke`
- `dependency-review`

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
rg -n "package-test|build-app|ui-smoke|dependency-review" .github/workflows
```
