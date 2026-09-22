# Adding the app monorepo

The quickstart works with the public `ghcr.io/akuity/guestbook` image so you
never have to build anything. When you're ready to promote **your own** app,
add [akp-monorepo](https://github.com/adamancini/akp-monorepo): application
source + GitHub Actions that build and tag images. CI and GitOps stay fully
decoupled — they share only an **image-tag contract**, never a token.

## The contract

| Kind | Tag pattern | Built when | Watched by |
|---|---|---|---|
| Release | `<run#>-<color>` matching `^\d+-[a-z]+$` (e.g. `42-blue`) | merge to main | your app's Warehouse |
| Preview | `pr-<N>-<color>` matching `^pr-\d+-.+$` | PR opened/updated | per-PR Warehouses (previews) |

The two regexes are mutually exclusive by design — release pipelines can never
pick up a PR image and vice versa.

## Steps

1. **Fork [akp-monorepo](https://github.com/adamancini/akp-monorepo)** (keep
   the name, keep it public), run its `personalize.sh`, and enable GitHub
   Actions on the fork.
2. **Trigger a first release**: change anything under `apps/rollouts-app/`,
   merge to main. CI publishes
   `ghcr.io/<you>/akp-monorepo-rollouts-app:<run#>-<color>`.
3. **Make the GHCR package public** (GitHub → package → settings → visibility)
   so Kargo can watch it without registry credentials.
4. **Point a pipeline at it.** Easiest: copy an existing app dir (e.g.
   `guestbook-kustomize` → `apps/rollouts-app/`), rename per the
   [onboarding conventions](onboarding.md), then change:

   ```yaml
   # kargo/warehouse.yaml — subscription
   - image:
       repoURL: ghcr.io/<you>/akp-monorepo-rollouts-app
       imageSelectionStrategy: NewestBuild   # run-number tags aren't semver
       allowTagsRegexes:
       - ^\d+-[a-z]+$
   ```

   ```yaml
   # kargo/tasks.yaml — the image var
   - name: image
     value: ghcr.io/<you>/akp-monorepo-rollouts-app
   ```

   and update the image reference in your `base/` or `chart/` manifests
   (the rollouts-app listens on port 8080).
5. Merge — bootstrap discovers the new app automatically. Add its Kargo git
   credentials (`add-credentials.sh`), then promote your own image end to end.

## Going further: PR preview environments

The rendered-branch machinery you already have (`guestbook-helm-rendered`) is
the same primitive behind ephemeral PR previews: an ApplicationSet
`pullRequest` generator creates a per-PR Kargo Warehouse (scoped to
`^pr-<N>-.+$` tags) and Stage from a small Helm template, promotions render to
an `env-ephemeral/pr-<N>` branch, and closing the PR prunes everything. Ask
the platform team for the `demo-ephemeral` reference implementation when you
want this — it needs the monorepo's preview workflow plus a GitHub token for
the PR generator.
