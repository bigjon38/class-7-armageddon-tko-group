output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.kamaus_alb01.dns_name
}
output "app_domain" {
  description = "Your app domain"
  value       = "https://app.kamaus-labs.online"
}
output "acm_certificate_arn" {
  description = "ACM Certificate ARN for HTTPS"
  value       = var.cloudfront_acm_cert_arn
}
