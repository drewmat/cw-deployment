# cw-deployment

Production-style AWS platform as code: a two-replica Python API on EKS talking to a
private RDS Postgres instance, and a static frontend on S3 + CloudFront. Terraform
provisions the infrastructure, ArgoCD deploys the workloads from Git, and GitHub Actions
automates every step through OIDC. There are no static AWS credentials anywhere.

**Start with [ARCHITECTURE.md](ARCHITECTURE.md)**: design decisions, security choices,
trade-offs and step-by-step instructions.

| Path | Contents |
|---|---|
| [terraform/](terraform/) | `bootstrap/` (one-time), `envs/prod/`, `envs/prod-platform/`, reusable `modules/` |
| [gitops/](gitops/) | Helm charts ArgoCD syncs: platform add-ons, Karpenter resources, backend |
| [backend/](backend/) | Flask service: `GET /` runs `SELECT 1` on RDS and returns JSON |
| [frontend/](frontend/) | Static site and build script |
| [.github/workflows/](.github/workflows/) | `terraform.yml`, `backend.yml`, `frontend.yml` |

## How it fits together

1. Push to `main`. GitHub Actions assumes an AWS role via OIDC and applies Terraform
   after approval on the `prod` environment.
2. Terraform installs ArgoCD, which syncs everything under `gitops/` from this repo.
3. A backend change builds an image tagged with the Git SHA, pushes it to ECR and
   commits the new tag to `gitops/`. ArgoCD rolls it out.
4. A frontend change builds the site, syncs it to S3 and invalidates CloudFront.

The only manual step is the one-time bootstrap (OIDC provider, CI roles, state bucket),
described in [ARCHITECTURE.md](ARCHITECTURE.md#3-step-by-step-instructions).
