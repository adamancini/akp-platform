#!/usr/bin/env bash
# Adds git credentials to every Kargo project in this repo so promotions can
# push commits/branches to your fork. Kargo credentials are namespaced per
# project, which is why this loops.
#
# Requires: kargo CLI logged in (kargo login <your-kargo-url>), and a GitHub
# token with repo write access to your akp-platform fork.

set -e

PROJECTS=(
  guestbook-rendered
  guestbook-kustomize
  guestbook-helm
  guestbook-helm-rendered
  rollouts-app
)

echo -n "Enter GitHub username: "
read -r username
if [[ -z "$username" ]]; then
  echo "GitHub username is required." >&2
  exit 1
fi

echo -n "Enter GitHub token (repo write access; input hidden): "
read -rs token
echo ""
if [[ -z "$token" ]]; then
  echo "GitHub token is required." >&2
  exit 1
fi

# The repo URL Kargo pushes to — derived from the personalized manifests so
# this works after personalize.sh has run.
repo_url=$(grep -h 'repoURL: https://github.com' bootstrap/platform-aoa.yaml | head -1 | awk '{print $2}')
echo "Using repo URL: ${repo_url}"

for project in "${PROJECTS[@]}"; do
  echo "==> ${project}"
  kargo create repo-credentials github-creds \
    --project="${project}" \
    --git \
    --username="${username}" \
    --password="${token}" \
    --repo-url="${repo_url}"
done

echo ""
echo "Done. Each project now has a 'github-creds' git credential."
echo "Tip: for many projects, one shared/global credential may be cleaner —"
echo "see 'Option B' under step 4 in the README."
