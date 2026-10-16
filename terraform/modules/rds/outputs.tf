output "identifier" {
  value = module.db.db_instance_identifier
}

output "address" {
  value = module.db.db_instance_address
}

output "port" {
  value = module.db.db_instance_port
}

output "db_name" {
  value = module.db.db_instance_name
}

output "username" {
  value     = module.db.db_instance_username
  sensitive = true
}

output "master_user_secret_arn" {
  description = "Secrets Manager secret (JSON: username/password) managed by RDS."
  value       = module.db.db_instance_master_user_secret_arn
}
