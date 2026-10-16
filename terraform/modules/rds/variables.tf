variable "identifier" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "database_subnet_group_name" {
  type = string
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to reach Postgres (EKS node SG)."
  type        = list(string)
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "username" {
  type    = string
  default = "appadmin"
}

variable "engine_version" {
  type    = string
  default = "17"
}

variable "family" {
  type    = string
  default = "postgres17"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "multi_az" {
  type    = bool
  default = true
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "skip_final_snapshot" {
  description = "Set true only for throwaway environments."
  type        = bool
  default     = false
}
