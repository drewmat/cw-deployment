data "terraform_remote_state" "prod" {
  backend = "s3"
  config = {
    bucket = var.tf_state_bucket
    key    = "envs/prod/terraform.tfstate"
    region = var.region
  }
}

locals {
  infra        = data.terraform_remote_state.prod.outputs
  cluster_name = local.infra.cluster_name
  repo_url     = "https://github.com/${var.github_org}/${var.github_repo}.git"
}

data "aws_eks_cluster" "this" {
  name = local.cluster_name
}

# The only thing Terraform installs in the cluster. Everything else is
# reconciled from Git by ArgoCD.
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true

  atomic  = true
  timeout = 600

  values = [yamlencode({
    configs = {
      params = {
        # TLS terminates at the (optional) ingress; reach the UI with kubectl port-forward.
        "server.insecure" = true
      }
    }
  })]
}

# Root "app-of-apps": points ArgoCD at gitops/platform. Account/cluster-specific
# values (role ARNs, queue names, hostnames) come from Terraform outputs and are
# injected here, so none of them are committed to Git.
resource "helm_release" "root_app" {
  name       = "root-app"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = var.argocd_apps_chart_version
  namespace  = "argocd"

  depends_on = [helm_release.argocd]

  values = [yamlencode({
    applications = {
      platform = {
        namespace = "argocd"
        project   = "default"
        source = {
          repoURL        = local.repo_url
          targetRevision = var.git_revision
          path           = "gitops/platform"
          helm = {
            valuesObject = {
              repoURL        = local.repo_url
              targetRevision = var.git_revision

              cluster = {
                name   = local.cluster_name
                region = var.region
                vpcId  = local.infra.vpc_id
                domain = var.domain_name
              }

              irsa = {
                albController   = local.infra.irsa_role_arns.alb_controller
                externalDns     = local.infra.irsa_role_arns.external_dns
                externalSecrets = local.infra.irsa_role_arns.external_secrets
                karpenter       = local.infra.irsa_role_arns.karpenter
              }

              karpenter = {
                nodeRoleName      = local.infra.karpenter_node_role_name
                interruptionQueue = local.infra.karpenter_queue_name
              }

              backend = {
                apiHostname     = local.infra.api_hostname
                corsOrigin      = "https://${local.infra.frontend_hostname}"
                imageRepository = local.infra.ecr_repository_url
                db = {
                  host      = local.infra.rds_address
                  name      = local.infra.rds_db_name
                  secretArn = local.infra.rds_secret_arn
                }
              }
            }
          }
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = "argocd"
        }
        syncPolicy = {
          automated = {
            prune    = true
            selfHeal = true
          }
          syncOptions = ["ServerSideApply=true"]
        }
      }
    }
  })]
}
