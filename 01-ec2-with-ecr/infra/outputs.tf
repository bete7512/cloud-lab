output "ec2_instance_id" {
  value = module.ec2.ec2_instance_id
  description = "The ID of the EC2 instance"
}

output "ec2_public_ip" {
  value = module.ec2.ec2_public_ip
  description = "The public IP address of the EC2 instance"
}

output "ecr_repository_url" {
  value = module.ecr.ecr_repository_url
  description = "The URL of the ECR repository"
}


