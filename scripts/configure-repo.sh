#!/usr/bin/env bash
#
# Configure GitHub repository settings:
# - Allow only squash merging
# - Enable auto-merge
# - Require CI to pass before merging to master
#
# Prerequisites: gh CLI authenticated with repo admin permissions
#   gh auth login
#
# Usage: ./scripts/configure-repo.sh

set -euo pipefail

REPO="yshmarov/yshmarov.github.io"
BRANCH="master"

echo "Configuring repository settings for ${REPO}..."

# 1. Allow only squash merging and enable auto-merge
gh repo edit "$REPO" \
  --enable-squash-merge \
  --disable-merge-commit \
  --disable-rebase-merge \
  --enable-auto-merge

echo "✓ Merge settings updated: squash-only, auto-merge enabled"

# 2. Set branch protection on master requiring CI to pass
gh api --method PUT "repos/${REPO}/branches/${BRANCH}/protection" \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": false,
    "contexts": ["build-and-test"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null
}
EOF

echo "✓ Branch protection updated: CI (build-and-test) required to pass"
echo "Done."
