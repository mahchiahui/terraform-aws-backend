terraform {
  backend "s3" {
    bucket         = "terraform-aws-backend-bucket"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-aws-backend-locks"
    encrypt        = true
  }
}