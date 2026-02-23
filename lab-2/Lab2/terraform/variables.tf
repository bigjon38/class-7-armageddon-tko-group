variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "project_name" {
  type    = string
  default = "kamau"
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}
variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}
variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}
variable "ec2_ami_id" {
  type    = string
  default = "ami-0885b1f6bd170450c"
}
variable "ec2_instance_type" {
  type    = string
  default = "t3.micro"
}
variable "db_engine" {
  type    = string
  default = "mysql"
}
variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}
variable "db_name" {
  type    = string
  default = "labdb"
}
variable "db_username" {
  type    = string
  default = "admin"
}
variable "db_password" {
  type      = string
  sensitive = true
  default   = "LabPassword123!"
}
variable "sns_email_endpoint" {
  type    = string
  default = "jayekamau@gmail.com"
}
variable "domain_name" {
  type    = string
  default = "kamaus-labs.online"
}
variable "app_subdomain" {
  type    = string
  default = "app"
}
variable "cloudfront_acm_cert_arn" {
  type = string
}
