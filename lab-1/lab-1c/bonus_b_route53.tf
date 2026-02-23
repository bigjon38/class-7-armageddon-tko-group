resource "aws_route53_zone" "kamaus_zone01" {
  name = "kamaus-labs.online"
}

resource "aws_route53_record" "app_record" {
  zone_id = aws_route53_zone.kamaus_zone01.zone_id
  name    = "app.kamaus-labs.online"
  type    = "A"
  alias {
    name                   = aws_lb.kamaus_alb01.dns_name
    zone_id                = aws_lb.kamaus_alb01.zone_id
    evaluate_target_health = true
  }
}
