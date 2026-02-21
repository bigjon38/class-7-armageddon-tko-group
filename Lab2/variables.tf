variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "domain_name" {
  type    = string
  default = "kamaus-labs.online"
}

variable "cloudfront_acm_cert_arn" {
  type = string
}

variable "alb_arn" {
  description = "ARN of the existing Lab 1 ALB"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the existing Lab 1 ALB"
  type        = string
}

variable "https_listener_arn" {
  description = "ARN of the existing Lab 1 HTTPS listener"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the existing Lab 1 target group"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the existing Lab 1 ALB"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
  default     = "Z04168233AYW3RDMIX03H"
}
