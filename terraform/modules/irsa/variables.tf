variable "name_prefix" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "hosted_zone_arn" {
  description = "Route53 zone ExternalDNS may modify."
  type        = string
}

variable "secret_arns" {
  description = "Secrets Manager secrets External Secrets may read."
  type        = list(string)
}
