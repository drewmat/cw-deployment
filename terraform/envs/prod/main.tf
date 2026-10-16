data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

data "aws_caller_identity" "current" {}

locals {
  name         = "${var.project}-${var.environment}"
  cluster_name = local.name
  azs          = slice(data.aws_availability_zones.available.names, 0, 3)

  site_hostname = "${var.frontend_subdomain}.${var.domain_name}"
  api_hostname  = "${var.api_subdomain}.${var.domain_name}"
  # Must match frontend_bk in terraform/bootstrap (the CI role is scoped to it).
  frontend_bucket = "${local.name}-frontend-${data.aws_caller_identity.current.account_id}"
}

module "vpc" {
  source = "../../modules/vpc"

  name               = local.name
  azs                = local.azs
  cluster_name       = local.cluster_name
  single_nat_gateway = var.single_nat_gateway
}

module "eks" {
  source = "../../modules/eks"

  cluster_name                 = local.cluster_name
  kubernetes_version           = var.eks_version
  vpc_id                       = module.vpc.vpc_id
  private_subnet_ids           = module.vpc.private_subnets
  endpoint_public_access_cidrs = var.eks_public_access_cidrs
}

module "rds" {
  source = "../../modules/rds"

  identifier                 = "${local.name}-postgres"
  vpc_id                     = module.vpc.vpc_id
  database_subnet_group_name = module.vpc.database_subnet_group_name
  allowed_security_group_ids = [module.eks.node_security_group_id]

  multi_az            = var.rds_multi_az
  deletion_protection = var.rds_deletion_protection
  skip_final_snapshot = !var.rds_deletion_protection
}

module "irsa" {
  source = "../../modules/irsa"

  name_prefix       = local.name
  oidc_provider_arn = module.eks.oidc_provider_arn
  hosted_zone_arn   = data.aws_route53_zone.this.arn
  secret_arns       = [module.rds.master_user_secret_arn]
}

# CloudFront only accepts certificates from us-east-1.
module "acm_cloudfront" {
  source    = "../../modules/acm"
  providers = { aws = aws.us_east_1 }

  domain_name = var.domain_name
  zone_id     = data.aws_route53_zone.this.zone_id
}

# The ALB controller auto-discovers a cert in the cluster's region by Ingress host,
# so no ARN is passed to the manifests. Redundant when the region is us-east-1.
module "acm_regional" {
  source = "../../modules/acm"

  create      = var.region != "us-east-1"
  domain_name = var.domain_name
  zone_id     = data.aws_route53_zone.this.zone_id
}

module "frontend" {
  source = "../../modules/frontend"

  bucket_name     = local.frontend_bucket
  site_hostname   = local.site_hostname
  zone_id         = data.aws_route53_zone.this.zone_id
  certificate_arn = module.acm_cloudfront.certificate_arn
}

module "observability" {
  source = "../../modules/observability"

  name                       = local.name
  alert_email                = var.alert_email
  rds_instance_identifier    = module.rds.identifier
  cloudfront_distribution_id = module.frontend.distribution_id
}

# Repo name is "<project>/backend" to match the ECR ARN in terraform/bootstrap.
module "ecr_backend" {
  source = "../../modules/ecr"

  name         = "${var.project}/backend"
  force_delete = !var.rds_deletion_protection
}
