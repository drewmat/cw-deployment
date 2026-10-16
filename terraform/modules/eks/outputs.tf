output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "node_security_group_id" {
  value = module.eks.node_security_group_id
}

output "karpenter_iam_role_arn" {
  description = "IRSA role for the Karpenter controller."
  value       = module.karpenter.iam_role_arn
}

output "karpenter_node_iam_role_name" {
  description = "Referenced by the EC2NodeClass `role` field."
  value       = module.karpenter.node_iam_role_name
}

output "karpenter_queue_name" {
  description = "Referenced by the Karpenter chart `settings.interruptionQueue`."
  value       = module.karpenter.queue_name
}
