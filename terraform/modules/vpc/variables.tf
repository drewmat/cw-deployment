variable "name" {
  type = string
}

variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type = list(string)
}

variable "cluster_name" {
  type = string
}

variable "single_nat_gateway" {
  type    = bool
  default = false
}