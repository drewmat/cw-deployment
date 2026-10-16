variable "create" {
  description = "Set false to skip the certificate (e.g. a regional cert that would duplicate the us-east-1 one)."
  type        = bool
  default     = true
}

variable "domain_name" {
  type = string
}

variable "zone_id" {
  type = string
}
