variable "name" {
  type = string
}

variable "alert_email" {
  type = string
}

variable "rds_instance_identifier" {
  type = string
}

variable "cloudfront_distribution_id" {
  description = "Optional. CloudFront metrics only exist in us-east-1, so the module must run there to use this."
  type        = string
  default     = null
}
