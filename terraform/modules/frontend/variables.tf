variable "bucket_name" {
  description = "Must match the bucket the CI frontend role is allowed to write to (see bootstrap)."
  type        = string
}

variable "site_hostname" {
  description = "FQDN served by CloudFront, e.g. app.example.com."
  type        = string
}

variable "zone_id" {
  type = string
}

variable "certificate_arn" {
  description = "us-east-1 ACM certificate covering site_hostname."
  type        = string
}

variable "force_destroy" {
  type    = bool
  default = false
}
