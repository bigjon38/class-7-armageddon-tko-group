# ============================================================
# Lab 2 - ALB in correct VPC
# ============================================================

resource "aws_security_group" "alb_sg" {
  name        = "kamau-lab2-alb-sg"
  description = "ALB security group - CloudFront only"
  vpc_id      = "vpc-0190e526ebad115f5"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "alb_ingress_cf443" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb_sg.id
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cf_origin_facing.id]
  description       = "Allow HTTP from CloudFront IPs"
}

resource "aws_lb" "lab2_alb" {
  name               = "kamau-lab2-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = ["subnet-0e652aa572267b78a", "subnet-07deb68295e45ab9c"]
}

resource "aws_lb_target_group" "lab2_tg" {
  name     = "kamau-lab2-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-0190e526ebad115f5"

  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group_attachment" "lab2_ec2" {
  target_group_arn = aws_lb_target_group.lab2_tg.arn
  target_id        = aws_instance.lab2_ec2.id
  port             = 80
}

resource "aws_lb_listener" "lab2_http" {
  load_balancer_arn = aws_lb.lab2_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lab2_tg.arn
  }
}

resource "aws_lb_listener" "lab2_https" {
  load_balancer_arn = aws_lb.lab2_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.cloudfront_acm_cert_arn
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lab2_tg.arn
  }
}
