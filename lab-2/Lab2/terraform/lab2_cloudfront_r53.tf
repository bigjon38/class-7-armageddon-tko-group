# ============================================================
# Lab 2 – Route53 DNS pointing to CloudFront
# Purpose: Your domains now resolve to CloudFront, not ALB
# ============================================================

# Apex domain: kamaus-labs.online → CloudFront
resource "aws_route53_record" "apex_cf01" {
  zone_id = "Z04168233AYW3RDMIX03H"
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cf01.domain_name
    zone_id                = aws_cloudfront_distribution.cf01.hosted_zone_id
    evaluate_target_health = false
  }
}

# App subdomain: app.kamaus-labs.online → CloudFront
resource "aws_route53_record" "app_cf01" {
  zone_id = "Z04168233AYW3RDMIX03H"
  name    = "app.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cf01.domain_name
    zone_id                = aws_cloudfront_distribution.cf01.hosted_zone_id
    evaluate_target_health = false
  }
}
