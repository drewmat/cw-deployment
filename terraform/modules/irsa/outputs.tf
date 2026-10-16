output "alb_controller_role_arn" {
  value = module.alb_controller.arn
}

output "external_dns_role_arn" {
  value = module.external_dns.arn
}

output "external_secrets_role_arn" {
  value = module.external_secrets.arn
}
