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
  type = string
}

variable "tf_state_bucket" {
  description = "State bucket holding envs/prod outputs (read via terraform_remote_state)."
  type        = string
}

variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "git_revision" {
  description = "Branch/tag ArgoCD tracks."
  type        = string
  default     = "main"
}

variable "argocd_chart_version" {
  type    = string
  default = "10.9.7"
}

variable "argocd_apps_chart_version" {
  type    = string
  default = "2.0.6"
}
