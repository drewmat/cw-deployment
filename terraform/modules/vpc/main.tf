module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.7"

  name = var.name
  cidr = var.cidr

  azs              = var.azs
  public_subnets   = [for i, _ in var.azs : cidrsubnet(var.cidr, 4, i)]
  private_subnets  = [for i, _ in var.azs : cidrsubnet(var.cidr, 4, i + 4)]
  database_subnets = [for i, _ in var.azs : cidrsubnet(var.cidr, 4, i + 8)]

  create_database_subnet_group = true
  enable_nat_gateway           = true
  single_nat_gateway           = var.single_nat_gateway
  one_nat_gateway_per_az       = !var.single_nat_gateway
  enable_dns_hostnames         = true
  enable_dns_support           = true

  # ALB auto-discovery tags
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "karpenter.sh/discovery"                    = var.cluster_name
  }
}