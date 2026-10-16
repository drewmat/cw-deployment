# EKS control plane + a small managed "system" node group. Everything else
# (application capacity) is provisioned by Karpenter from NodePool/EC2NodeClass
# manifests that live in the GitOps repo.
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Public endpoint so GitHub-hosted runners can install the platform layer;
  # private endpoint so nodes talk to the API inside the VPC.
  endpoint_public_access       = true
  endpoint_private_access      = true
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs

  # IRSA (OIDC provider) for ALB controller, ExternalDNS, External Secrets, Karpenter.
  enable_irsa = true

  # Access entries (not aws-auth). The identity running `terraform apply`
  # (the OIDC tf-apply role) becomes cluster admin.
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  enabled_log_types = ["api", "audit", "authenticator"]

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  eks_managed_node_groups = {
    system = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.system_node_instance_types

      min_size     = 2
      max_size     = 3
      desired_size = var.system_node_desired_size

      labels = {
        "node-role" = "system"
      }
    }
  }

  # Karpenter discovers the node security group by this tag.
  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}

# Trust policy letting the Karpenter service account assume the controller role
# via IRSA. The v21 karpenter submodule only ships a Pod Identity trust
# statement, so the IRSA statement is merged in as an extra assume-role document.
data "aws_iam_policy_document" "karpenter_irsa_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:karpenter"]
    }
  }
}

# Karpenter: controller IAM role (IRSA), node IAM role + access entry, and the
# SQS queue / EventBridge rules for spot interruption handling.
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.0"

  cluster_name = module.eks.cluster_name

  create_pod_identity_association         = false
  iam_role_source_assume_policy_documents = [data.aws_iam_policy_document.karpenter_irsa_trust.json]

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}
