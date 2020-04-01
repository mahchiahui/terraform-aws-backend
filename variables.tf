variable "S3_BUCKET_NAME" {
  type        = string
  description = "S3 Bucket Name"
}

variable "S3_ENC" {
  type        = string
  description = "S3 Bucket Encryption Algorithm"
}

variable "S3_VER" {
  type        = string
  description = "S3 Versioning"
}

variable "DYNAMODB_TABLE_NAME" {
  type        = string
  description = "Dynamo DB table name"
}

variable "REGION" {
  type        = string
  description = "AWS Region"
}