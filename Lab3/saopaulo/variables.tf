variable "aws_region" {
  default = "sa-east-1"
}

variable "project" {
  default = "liberdade"
}

variable "vpc_cidr" {
  default = "10.20.0.0/16"
}

variable "tokyo_cidr" {
  default = "10.10.0.0/16"
}

variable "tokyo_tgw_id" {
  description = "Tokyo TGW ID - paste output from Tokyo deploy here"
  type        = string
}

variable "tokyo_rds_endpoint" {
  description = "Tokyo RDS endpoint - passed in from Tokyo outputs"
  type        = string
  sensitive   = true
}
