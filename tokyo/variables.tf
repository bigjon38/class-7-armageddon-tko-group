variable "aws_region" {
  default = "ap-northeast-1"
}

variable "project" {
  default = "shinjuku"
}

variable "vpc_cidr" {
  default = "10.10.0.0/16"
}

variable "saopaulo_cidr" {
  default = "10.20.0.0/16"
}

variable "db_username" {
  default = "adminuser"
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "saopaulo_tgw_id" {
  description = "Sao Paulo TGW ID - filled in after Sao Paulo deploys"
  type        = string
  default     = ""
}
