output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.kamau_cf.domain_name
}

output "alb_dns_name" {
  description = "ALB DNS name - direct access should return 403"
  value       = aws_lb.lab2_alb.dns_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.kamau_cf.id
}
