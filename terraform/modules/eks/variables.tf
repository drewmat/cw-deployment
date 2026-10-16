variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the control plane ENIs and the system node group."
  type        = list(string)
}

variable "endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint (needed by GitHub-hosted runners)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "system_node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "system_node_desired_size" {
  type    = number
  default = 2
}
