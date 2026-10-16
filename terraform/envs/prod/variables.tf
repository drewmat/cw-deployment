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

variable "domain_name" {
  description = "Existing public Route53 hosted zone, e.g. example.com"
  type        = string
}

variable "alert_email" {
  type = string
}

variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "eks_version" {
  type    = string
  default = "1.35"
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "eks_public_access_cidrs" {
  description = "CIDRs allowed to reach the EKS public endpoint. Tighten if using self-hosted runners."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "rds_multi_az" {
  type    = bool
  default = true
}

variable "rds_deletion_protection" {
  description = "false also skips the final snapshot (throwaway environments only)."
  type        = bool
  default     = true
}

variable "frontend_subdomain" {
  type    = string
  default = "app"
}

variable "api_subdomain" {
  description = "Hostname ExternalDNS publishes for the backend Ingress."
  type        = string
  default     = "api"
}
