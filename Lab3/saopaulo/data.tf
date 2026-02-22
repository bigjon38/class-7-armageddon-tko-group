data "terraform_remote_state" "tokyo" {
  backend = "local"

  config = {
    path = "${path.module}/../tokyo/terraform.tfstate"
  }
}
