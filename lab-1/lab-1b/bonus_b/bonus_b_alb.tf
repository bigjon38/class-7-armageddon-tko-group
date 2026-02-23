resource "aws_lb" "kamaus_alb01" {
  name               = "kamaus-alb01"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.alb_sg_existing.id]
  subnets            = ["subnet-074417f72c4901c31", "subnet-0b43eb3cb10ada955"]
}

resource "aws_lb_target_group" "kamaus_tg01" {
  name     = "kamaus-tg01"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-0190e526ebad115f5"

  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group_attachment" "ec2" {
  target_group_arn = aws_lb_target_group.kamaus_tg01.arn
  target_id        = aws_instance.chewbacca_ec201.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.kamaus_alb01.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.kamaus_alb01.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.cloudfront_acm_cert_arn
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kamaus_tg01.arn
  }
}
