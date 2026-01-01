# Backend Configuration Variables
# These variables are NOT used by Terraform itself.
# They are only used by the init.sh script to read backend configuration from terraform.tfvars.
# Terraform backend configuration is provided via -backend-config flags during terraform init.

variable "backend_bucket" {
  type        = string
  description = "S3 bucket name for Terraform remote state (used by init.sh script only)"
  default     = null
}

variable "backend_key" {
  type        = string
  description = "S3 key/path for Terraform state file (used by init.sh script only)"
  default     = null
}

variable "backend_dynamodb_table" {
  type        = string
  description = "DynamoDB table name for Terraform state locking (used by init.sh script only)"
  default     = null
}

variable "backend_region" {
  type        = string
  description = "AWS region for Terraform backend (used by init.sh script only)"
  default     = null
}

