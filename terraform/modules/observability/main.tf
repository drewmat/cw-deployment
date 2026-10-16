data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# NOTE: not encrypted with the AWS-managed SNS key on purpose: CloudWatch
# alarms cannot publish to topics encrypted with it. Use a CMK if encryption is required.
resource "aws_sns_topic" "alerts" {
  name = "${var.name}-alerts"
}

data "aws_iam_policy_document" "alerts" {
  statement {
    sid       = "AllowCloudWatchAlarms"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alerts.arn]

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "alerts" {
  arn    = aws_sns_topic.alerts.arn
  policy = data.aws_iam_policy_document.alerts.json
}

# The recipient must click the confirmation link AWS emails them.
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

locals {
  rds_alarms = {
    cpu = {
      metric    = "CPUUtilization"
      operator  = "GreaterThanThreshold"
      threshold = 80
      desc      = "RDS CPU above 80% for 10 minutes"
    }
    storage = {
      metric    = "FreeStorageSpace"
      operator  = "LessThanThreshold"
      threshold = 2 * 1024 * 1024 * 1024
      desc      = "RDS free storage below 2 GiB"
    }
    connections = {
      metric    = "DatabaseConnections"
      operator  = "GreaterThanThreshold"
      threshold = 60
      desc      = "RDS connection count above 60"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "rds" {
  for_each = local.rds_alarms

  alarm_name          = "${var.name}-rds-${each.key}"
  alarm_description   = each.value.desc
  namespace           = "AWS/RDS"
  metric_name         = each.value.metric
  dimensions          = { DBInstanceIdentifier = var.rds_instance_identifier }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  comparison_operator = each.value.operator
  threshold           = each.value.threshold
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx" {
  count = var.cloudfront_distribution_id == null ? 0 : 1

  alarm_name          = "${var.name}-cloudfront-5xx"
  alarm_description   = "CloudFront 5xx error rate above 5%"
  namespace           = "AWS/CloudFront"
  metric_name         = "5xxErrorRate"
  dimensions          = { DistributionId = var.cloudfront_distribution_id, Region = "Global" }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  comparison_operator = "GreaterThanThreshold"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  lifecycle {
    precondition {
      condition     = data.aws_region.current.region == "us-east-1"
      error_message = "CloudFront metrics are only published in us-east-1; run this module there or omit cloudfront_distribution_id."
    }
  }
}
