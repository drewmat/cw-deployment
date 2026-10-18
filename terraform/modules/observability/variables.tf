variable "name" {
  type = string
}

variable "alert_email" {
  type = string
}

variable "rds_instance_identifier" {
  type = string
}

variable "enable_cloudfront_alarm" {
  description = "Create the CloudFront 5xx alarm. A plain flag because the distribution ID is unknown until apply. CloudFront metrics only exist in us-east-1."
  type        = bool
  default     = false
}

variable "cloudfront_distribution_id" {
  description = "Required when enable_cloudfront_alarm is true."
  type        = string
  default     = null
}
