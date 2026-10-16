# Bucket/region are injected by CI: terraform init -backend-config="bucket=..." -backend-config="region=..."
terraform {
  backend "s3" {
    key          = "envs/prod/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}
