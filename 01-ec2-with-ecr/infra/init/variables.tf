variable "aws_region" {
  type        = string
  description = "AWS region for resources"
  default     = "eu-central-1"
}

variable "state_bucket_name" {
  type        = string
  description = "S3 bucket name for Terraform remote state"
}

variable "state_lock_table_name" {
  type        = string
  description = "DynamoDB table name for Terraform state locking"
}

variable "role_name" {
  type        = string
  description = "IAM role name for GitHub Actions OIDC"
}

variable "policy_arn" {
  type        = string
  description = "IAM policy ARN to attach to the GitHub Actions role"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository in format 'org/repo' (e.g., 'username/repo')"
}

variable "branch" {
  type        = string
  description = "GitHub branch allowed to assume the role"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  default     = {}
}