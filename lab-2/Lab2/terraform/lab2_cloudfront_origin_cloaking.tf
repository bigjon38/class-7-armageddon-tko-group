cat > lab2_cloudfront_origin_cloaking.tf << 'EOF'
# ============================================================
# Lab 2 - Origin Cloaking
# ============================================================

data "aws_ec2_managed_prefix_list" "cf_origin_facing01" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "random_password" "origin_header_value01" {
  length  = 32
  special = false
}

# Use existing ALB security group
data "aws_security_group" "alb_sg_existing" {
  id = "sg-0ae34b45939bfc684"
}

resource "aws_security_group_rule" "alb_ingress_cf44301" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = data.aws_security_group.alb_sg_existing.id
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cf_origin_facing01.id]
  description       = "Allow HTTPS only from CloudFront IPs"
}

resource "aws_lb_listener_rule" "require_origin_header01" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kamaus_tg01.arn
  }

  condition {
    http_header {
      http_header_name = "X-Kamau-Growl"
      values           = [random_password.origin_header_value01.result]
    }
  }
}

resource "aws_lb_listener_rule" "default_block01" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 99

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}
EOF