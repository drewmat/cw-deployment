# Separate state from envs/prod so the cluster exists before any Kubernetes/Helm provider is configured.
terraform {
  backend "s3" {
    key          = "envs/prod-platform/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}
