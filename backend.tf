resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.s3_bucket_name}"
  versioning {
    enabled = true
  }
  force_destroy = true
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "${var.s3_bucket_encryption}"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.DynamoDB_name}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

terraform {
  backend "s3" {
    bucket         = "${var.s3_bucket_name}"
    key            = "global/s3/terraform.tfstate"
    region         = "${var.region}"
    dynamodb_table = "${var.DynamoDB_name}"
    encrypt        = true
  }
}