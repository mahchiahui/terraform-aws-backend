output "s3_name" {
  value       = module.s3_state.S3_id
  description = "The s3 bucket name for storing state files"
}

output "dynamodb_name" {
  value       = module.dynamodb_state.dynamodb_id
  description = "The dynamodb table name for storing state files"
}