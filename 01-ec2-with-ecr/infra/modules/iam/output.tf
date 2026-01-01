output "iam_role_arn" {
  value = aws_iam_role.ec2_instance_role.arn
}

output "iam_role_name" {
  value = aws_iam_role.ec2_instance_role.name
}
