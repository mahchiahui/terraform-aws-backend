variable "s3_bucket_name" {
    type = "string"
    description = "S3 Bucket Name"
}

variable "s3_bucket_encryption" {
    type = "string"
    description = "S3 Bucket Encryption Algorithm"
}

variable "DynamoDB_name" {
    type = "string"
    description = "Dynamo DB Name"
}

variable "region" {
    type = "string"
    description = "AWS Region"
}

variable "backend_key" {
    type = "string"
    description = "path to store terraform state file"
}