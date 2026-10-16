output "certificate_arn" {
  description = "ARN of the validated certificate (null when create = false)."
  value       = try(aws_acm_certificate_validation.this[0].certificate_arn, null)
}
