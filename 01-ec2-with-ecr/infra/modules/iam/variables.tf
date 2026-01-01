variable "iam_role_name" {
  type = string
  description = "The name of the IAM role"
}

variable "ecr_repository_arn" {
  type = string
  description = "The ARN of the ECR repository"
}