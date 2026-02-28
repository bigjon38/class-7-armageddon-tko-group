# ============================================================
# Lab 2 - CloudFront Distribution
# ============================================================

resource "aws_cloudfront_cache_policy" "static_cache" {
  name        = "kamau-lab2-static-cache"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

resource "aws_cloudfront_origin_request_policy" "static_orp" {
  name = "kamau-lab2-static-orp"

  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "none"
  }
  query_strings_config {
    query_string_behavior = "none"
  }
}

resource "aws_cloudfront_distribution" "kamau_cf" {
  origin {
    domain_name = aws_lb.lab2_alb.dns_name
    origin_id   = "kamau-lab2-alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Kamau-Growl"
      value = random_password.origin_secret.result
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "Lab 2 - Kamau CloudFront distribution"

  aliases = [var.domain_name, "app.${var.domain_name}"]

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "kamau-lab2-alb-origin"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  ordered_cache_behavior {
    path_pattern             = "/static/*"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "kamau-lab2-alb-origin"
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = aws_cloudfront_cache_policy.static_cache.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.static_orp.id
  }

  viewer_certificate {
    acm_certificate_arn      = var.cloudfront_acm_cert_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  web_acl_id = aws_wafv2_web_acl.kamau_cf_waf.arn

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Lab  = "2"
    Name = "kamau-cf"
  }

  depends_on = [aws_wafv2_web_acl.kamau_cf_waf]
}
