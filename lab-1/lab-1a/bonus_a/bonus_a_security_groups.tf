resource "aws_security_group" "private_ec2_sg" {
  name        = "private_ec2_sg"
  description = "Private EC2 Security Group"
  vpc_id      = aws_vpc.chewbacca_vpc01.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
}

resource "aws_security_group" "allow_https" {
  name        = "allow_https"
  description = "VPC Endpoint Security Group"
  vpc_id      = aws_vpc.chewbacca_vpc01.id
}

resource "aws_security_group_rule" "ec2_allow_ssh_from_alb" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.private_ec2_sg.id
  source_security_group_id = aws_security_group.allow_https.id
}

resource "aws_security_group_rule" "allow_https_from_ec2" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.allow_https.id
  source_security_group_id = aws_security_group.private_ec2_sg.id
}
