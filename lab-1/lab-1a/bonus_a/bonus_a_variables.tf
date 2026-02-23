variable "enable_vpc_endpoints" {
  type    = bool
  default = false
}
variable "subnet_selection" {
  type = string
}
variable "parameter_store_path_prefix" {
  type = string
}
variable "secrets_manager_secret_name" {
  type = string
}
variable "iam_configuration" {
  type    = map(string)
  default = {}
}
