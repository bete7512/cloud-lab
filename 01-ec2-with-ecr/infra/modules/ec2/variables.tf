variable "ami_id" {
  type = string
  description = "The ID of the AMI to use for the EC2 instance"
}
variable "ec2_iam_role_name" {
  type = string
  description = "The name of the IAM role to use for the EC2 instance"
}