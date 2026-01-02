terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    # Backend configuration uses partial configuration
    # Values are provided via -backend-config flags in terraform init
    # See BACKEND_CONFIG.md for details
    # 
    # GitHub Actions: Uses secrets TF_BACKEND_* with fallback defaults
    # Local: Use environment variables or backend.hcl file
  }
}

provider "aws" {
  region = "eu-central-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}


module "ecr" {
  source = "./modules/ecr"
  ecr_repository_name = "ecr-repository"
}

module "ec2" {
  source = "./modules/ec2"
  ami_id = data.aws_ami.ubuntu.id
  ec2_iam_role_name = module.iam.iam_role_name
}

module "iam" {
  source = "./modules/iam"
  iam_role_name = "ec2-instance-role"
  ecr_repository_arn = module.ecr.ecr_repository_arn
}

module "config" {
  source = "./modules/config"
  instance_id = module.ec2.ec2_instance_id
}