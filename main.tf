provider "aws" {
  region = "us-east-2"
}

module "webserver" {
  source = "github.com/mahchiahui/terraform-aws-module//services/webserver?ref=v0.0.2"
  server_name = "aws-webserver-2"
}