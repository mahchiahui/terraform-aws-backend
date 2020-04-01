provider "aws" {
  region = var.REGION
}

module "s3_state" {
  source             = "github.com/mahchiahui/terraform-aws-module//services/s3_state?ref=v0.0.5"
  s3_name            = var.S3_BUCKET_NAME
  versioning_enabled = var.S3_VER
  force_destroy      = true
  sse_algorithm      = var.S3_ENC
}

module "dynamodb_state" {
  source       = "github.com/mahchiahui/terraform-aws-module//services/dynamodb_state?ref=v0.0.5"
  db_name      = var.DYNAMODB_TABLE_NAME
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attr_name    = "LockID"
  attr_type    = "S"
}