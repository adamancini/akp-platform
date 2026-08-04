# rollouts-app — Kustomize overlays, promotions commit to main

Deploys the [akp-monorepo `rollouts-app`](https://github.com/adamancini/akp-monorepo/tree/main/apps/rollouts-app)
image. Same pattern as `guestbook-kustomize`: each environment is a Kustomize
overlay under `env/<stage>/`, synced by Argo CD **directly from main**. On
every promotion Kargo:

1. clones main,
2. runs `kustomize-set-image` to bump `newTag` in the stage's
   `env/<stage>/kustomization.yaml`,
3. commits and pushes to main,
4. syncs the Argo CD Application.

**Pipeline:** `Warehouse → dev → staging → prod`

## Env vars the app reads

`rollouts-app` reads `NAMESPACE`, `STAGE`, `SEMVER`, and `COMMIT` at runtime
(Dockerfile defaults are placeholders, overridden here):

| Var | Source | Why |
|---|---|---|
| `NAMESPACE` | Downward API (`fieldRef: metadata.namespace`) | Always accurate, zero per-env config. |
| `STAGE` | `app-config` ConfigMap, patched per overlay | Static per environment, matches the sedemo-platform `demo-ephemeral` pattern. |
| `SEMVER` | `replacements` block in each overlay, copied from the image tag `kustomize-set-image` just bumped | Never drifts from what's actually running; no second promotion step needed. |
| `COMMIT` | **Not wired here** | See below. |

**Why COMMIT isn't set:** this Warehouse is image-only (see the comment in
`kargo/warehouse.yaml`) — Kargo only ever sees `<run#>-<color>` tags, which
don't encode a git SHA, so there's no value to copy the way `SEMVER` copies
the tag. The commit that produced the image *is* recorded as the
`org.opencontainers.image.revision` OCI label by the publish/preview
workflows in akp-monorepo, but reading OCI labels at deploy time isn't
something Kustomize/Kargo does out of the box. If you want `COMMIT`
populated, the straightforward option is to make it a build-time value
instead: add `ARG COMMIT` / `ENV COMMIT=${COMMIT}` to the Dockerfile (same
shape as `COLOR`) and pass `--build-arg COMMIT=${{ github.sha }}` from the
publish/preview workflows — then it's baked into the image and this pipeline
doesn't need to touch it at all.

**Things to know**

- The Warehouse is **image-only**. Promotions commit to main, so subscribing
  to main from git would create a promote → new Freight → promote loop.
- Kargo needs git *write* credentials for this project to push to main — see
  the repo root README, step 5, or `add-credentials.sh`.
- **`prod` runs on a separate workload cluster.** Unlike every other app in
  this repo (all on `demo1`), `argocd/appset.yaml` uses Go templating to send
  `prod` to a `demo2` cluster destination while `dev`/`staging` stay on
  `demo1`. `demo2` must already be registered as an Argo CD cluster
  destination for this to sync — same requirement as `demo1` in the root
  README's prerequisites.
