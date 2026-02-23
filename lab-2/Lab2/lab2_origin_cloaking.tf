# ============================================================
# Lab 2 - Origin Cloaking
# ============================================================

data "aws_ec2_managed_prefix_list" "cf_origin_facing" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}



resource "random_password" "origin_secret" {
  length  = 32
  special = false
}

resource "aws_lb_listener_rule" "require_secret_header" {
  listener_arn = aws_lb_listener.lab2_https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lab2_tg.arn
  }

  condition {
    http_header {
      http_header_name = "X-Kamau-Growl"
      values           = [random_password.origin_secret.result]
    }
  }
}

resource "aws_lb_listener_rule" "block_direct_access" {
  listener_arn = aws_lb_listener.lab2_https.arn
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
