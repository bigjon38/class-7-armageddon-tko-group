# ============================================================
# Lab 2 - Route53 DNS pointing to CloudFront
# ============================================================

resource "aws_route53_record" "apex" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.kamau_cf.domain_name
    zone_id                = aws_cloudfront_distribution.kamau_cf.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "app" {
  zone_id = var.route53_zone_id
  name    = "app.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.kamau_cf.domain_name
    zone_id                = aws_cloudfront_distribution.kamau_cf.hosted_zone_id
    evaluate_target_health = false
  }
}
