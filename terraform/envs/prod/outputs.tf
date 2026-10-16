output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "rds_address" {
  value = module.rds.address
}

output "rds_db_name" {
  value = module.rds.db_name
}

output "rds_username" {
  value     = module.rds.username
  sensitive = true
}

output "rds_secret_arn" {
  value = module.rds.master_user_secret_arn
}

output "karpenter_node_role_name" {
  value = module.eks.karpenter_node_iam_role_name
}

output "karpenter_queue_name" {
  value = module.eks.karpenter_queue_name
}

output "irsa_role_arns" {
  value = {
    karpenter        = module.eks.karpenter_iam_role_arn
    alb_controller   = module.irsa.alb_controller_role_arn
    external_dns     = module.irsa.external_dns_role_arn
    external_secrets = module.irsa.external_secrets_role_arn
  }
}

output "frontend_url" {
  value = module.frontend.site_url
}

output "frontend_bucket" {
  value = module.frontend.bucket_name
}

output "cloudfront_distribution_id" {
  value = module.frontend.distribution_id
}

output "api_hostname" {
  description = "Used as API_URL (https://<this>) by the frontend build and as the Ingress host."
  value       = local.api_hostname
}

output "sns_topic_arn" {
  value = module.observability.sns_topic_arn
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ecr_repository_url" {
  value = module.ecr_backend.repository_url
}

output "frontend_hostname" {
  value = local.site_hostname
}
