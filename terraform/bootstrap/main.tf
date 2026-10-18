# ONE-TIME bootstrap: state bucket + GitHub OIDC provider + CI roles.
# This is the only unavoidable "chicken-and-egg" step: GitHub Actions cannot
# assume a role that does not exist yet. Run once with admin creds
# then everything else is 100% CI/CD.
terraform {
  required_version = ">= 1.16"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.69"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "project" {
  type    = string
  default = "cw-deployment"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}

data "aws_caller_identity" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  repo        = "${var.github_org}/${var.github_repo}"
  state_bkt   = "${var.project}-tfstate-${local.account_id}"
  frontend_bk = "${var.project}-${var.environment}-frontend-${local.account_id}"
  ecr_arn     = "arn:aws:ecr:${var.region}:${local.account_id}:repository/${var.project}/backend"

  # OIDC `sub` claim each role may be assumed from.
  # tf-apply is gated by the GitHub Environment "prod" (configure required
  # reviewers + a main-only deployment branch rule on that environment).
  roles = {
    tf-plan  = "repo:${local.repo}:pull_request"
    tf-apply = "repo:${local.repo}:environment:prod"
    frontend = "repo:${local.repo}:ref:refs/heads/main"
    backend  = "repo:${local.repo}:ref:refs/heads/main"
  }
}

# Create and configure the state S3 bucket
resource "aws_s3_bucket" "state" {
  bucket = local.state_bkt

  # This bucket holds every stack's state, including bootstrap's own once migrated.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# AWS validates GitHub's OIDC certificate chain itself; no thumbprint needed.
# NOTE: an account can have only one provider per URL. If it already exists,
# import it (or swap this for a data source).
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "trust" {
  for_each = local.roles

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [each.value]
    }
  }
}

resource "aws_iam_role" "gha" {
  for_each             = local.roles
  name                 = "${var.project}-gha-${each.key}"
  assume_role_policy   = data.aws_iam_policy_document.trust[each.key].json
  max_session_duration = 3600
}

# terraform plan (PRs): read-only + state/lock access
resource "aws_iam_role_policy_attachment" "plan_ro" {
  role       = aws_iam_role.gha["tf-plan"].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "state_access" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.state.arn}/*"]
  }
}

resource "aws_iam_role_policy" "plan_state" {
  name   = "state"
  role   = aws_iam_role.gha["tf-plan"].id
  policy = data.aws_iam_policy_document.state_access.json
}

# terraform apply (main): broad by necessity (creates IAM/EKS/VPC...).
# Trade-off documented in ARCHITECTURE.md; scope down with a permissions boundary in real life.
resource "aws_iam_role_policy_attachment" "apply_admin" {
  role       = aws_iam_role.gha["tf-apply"].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# frontend deploy: least privilege
data "aws_iam_policy_document" "frontend" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.frontend_bk}"]
  }
  statement {
    actions   = ["s3:PutObject", "s3:DeleteObject", "s3:GetObject"]
    resources = ["arn:aws:s3:::${local.frontend_bk}/*"]
  }
  statement {
    actions   = ["cloudfront:CreateInvalidation", "cloudfront:ListDistributions"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "frontend" {
  name   = "frontend-deploy"
  role   = aws_iam_role.gha["frontend"].id
  policy = data.aws_iam_policy_document.frontend.json
}

# backend: ECR push only
data "aws_iam_policy_document" "backend" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload", "ecr:PutImage", "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer",
    ]
    resources = [local.ecr_arn]
  }
}

resource "aws_iam_role_policy" "backend" {
  name   = "ecr-push"
  role   = aws_iam_role.gha["backend"].id
  policy = data.aws_iam_policy_document.backend.json
}

output "state_bucket" {
  value = aws_s3_bucket.state.bucket
}

output "github_actions_variables" {
  description = "Set these as (non-secret) GitHub repository VARIABLES."
  value = {
    AWS_ACCOUNT_ID  = local.account_id
    AWS_REGION      = var.region
    PROJECT_NAME    = var.project
    TF_STATE_BUCKET = aws_s3_bucket.state.bucket
  }
}
