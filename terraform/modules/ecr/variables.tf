variable "name" {
  description = "Repository name. Must match the ARN the CI backend role is scoped to (see bootstrap)."
  type        = string
}

variable "keep_last_images" {
  type    = number
  default = 30
}

variable "force_delete" {
  type    = bool
  default = false
}
