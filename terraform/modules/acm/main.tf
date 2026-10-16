# Apex + wildcard certificate, validated through DNS in the existing Route53 zone.
# The calling environment decides the region via the provider it passes in
# (CloudFront certificates must live in us-east-1).
resource "aws_acm_certificate" "this" {
  count = var.create ? 1 : 0

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  for_each = var.create ? {
    for dvo in aws_acm_certificate.this[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60

  # Certificates for the same name in different regions share validation records.
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "this" {
  count = var.create ? 1 : 0

  certificate_arn         = aws_acm_certificate.this[0].arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]
}
