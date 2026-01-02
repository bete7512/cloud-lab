resource "aws_ssm_parameter" "ec2_instance_id" {
  name = "/cloud-lab/01-ec2-with-ecr/ec2_instance_id"
  type = "String"
  overwrite  = true
  value = var.instance_id
  description = "The ID of the EC2 instance"
}
