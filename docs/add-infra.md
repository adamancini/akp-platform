# Managing the platform with Terraform

Everything this repo assumes exists — the Argo CD instance, the Kargo
instance, the `kargo` cluster destination, your workload cluster's agents —
can be created and managed declaratively with the
[akp-infra](https://github.com/adamancini/akp-infra) repo and the
[`akuity/akp` Terraform provider](https://registry.terraform.io/providers/akuity/akp/latest).

akp-infra is its own self-guided journey, applied in order:

1. **`01-argocd/`** — the hosted Argo CD instance (declarative management
   enabled, admin account configured).
2. **`02-kargo/`** — the hosted Kargo instance, plus registering it into
   Argo CD as the cluster destination named `kargo` — which is exactly what
   this repo's `bootstrap/kargo-apps.yaml` targets.
3. **`03-clusters/`** — registering workload clusters: the Argo CD agent
   (deploys your apps) and the Kargo agent (runs promotions and connects them
   back to Argo CD) per cluster.

## Which order to do things in

- **Fresh start:** run the akp-infra journey first (steps 1–3), then come back
  here and bootstrap (`platform-aoa.yaml`). The names line up out of the box:
  the Kargo destination is `kargo`, and you tell `personalize.sh` whatever you
  named your workload cluster.
- **Already created everything in the Akuity UI:** you can keep it that way —
  this repo doesn't care how the instances came to be. If you later want them
  under Terraform, akp-infra's `docs/importing-existing.md` walks through
  `terraform import` of existing instances and clusters instead of recreating
  them.

## Why bother?

Instance settings (RBAC, config management plugins, feature toggles), cluster
registrations, and agent sizing become reviewable PRs instead of UI clicks —
the same properties this repo gives your app delivery, extended down one
layer. Day-2 operations (upgrading instance versions, adding clusters,
rotating settings) are documented in akp-infra's `docs/day-2.md`.
