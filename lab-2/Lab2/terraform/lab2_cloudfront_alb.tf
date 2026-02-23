# ============================================================
# Lab 2 – CloudFront Distribution in Front of ALB
# Purpose: CloudFront becomes the only public entry point
# ============================================================

resource "aws_cloudfront_distribution" "cf01" {

  origin {
    domain_name = aws_lb.kamaus_alb01.dns_name
    origin_id   = "kamau-alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    # Secret header – CloudFront stamps this on every request
    # ALB checks for it – no header means 403
    custom_header {
      name  = "X-Kamau-Growl"
      value = random_password.origin_header_value01.result
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "Lab 2 – Kamau CloudFront distribution"

  # Your domain names
  aliases = [var.domain_name, "app.${var.domain_name}"]

  # Default behavior – no caching for dynamic content
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "kamau-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    # AWS managed CachingDisabled policy
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # Static assets – aggressive caching
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "kamau-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id          = aws_cloudfront_cache_policy.static_cache01.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.static_orp01.id
  }

  # SSL certificate
  viewer_certificate {
    acm_certificate_arn      = var.cloudfront_acm_cert_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # WAF attachment
  web_acl_id = aws_wafv2_web_acl.cf_waf01.arn

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Lab  = "2"
    Name = "kamau-cf01"
  }

  depends_on = [aws_wafv2_web_acl.cf_waf01]
}
