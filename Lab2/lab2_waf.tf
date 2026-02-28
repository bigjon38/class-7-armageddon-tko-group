# ============================================================
# Lab 2 - WAF at CloudFront Edge
# Must be created in us-east-1
# ============================================================

resource "aws_wafv2_web_acl" "kamau_cf_waf" {
  provider    = aws.us_east_1
  name        = "kamau-cf-waf"
  scope       = "CLOUDFRONT"
  description = "WAF for CloudFront distribution - Lab 2"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedCommonRules"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedCommonRules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "kamau-cf-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Lab  = "2"
    Name = "kamau-cf-waf"
  }
}
