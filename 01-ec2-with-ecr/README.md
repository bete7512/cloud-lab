# EC2 with ECR - Deploy Go App with Terraform & GitHub Actions

A complete infrastructure-as-code solution for deploying a containerized Go application to AWS EC2 using Terraform and GitHub Actions CI/CD.

## Architecture Overview

```
┌─────────────┐
│ User Push   │
│ (git push)  │
└──────┬──────┘
       │ user pushes for both app/infra change
       ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  GitHub Actions │────▶│       ECR       │────▶│       EC2       │
│   (CI/CD)       │     │  (Container     │     │  (Docker +      │
│                 │     │   Registry)     │     │   Nginx)        │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                                               │
         │              ┌─────────────────┐              │
         └─────────────▶│   SSM (Deploy)  │◀─────────────┘
                        └─────────────────┘
```

**What gets deployed:**
- **EC2 Instance**: Ubuntu 22.04 with Docker and Nginx (reverse proxy on port 80 → 8080)
- **ECR Repository**: Stores your Go application Docker images
- **IAM Roles**: Secure access for EC2 (pull from ECR, SSM) and GitHub Actions (OIDC)
- **Parameter Store**: Stores EC2 instance ID for deployment

---

## Project Structure

```
01-ec2-with-ecr/
├── app/                    # Go application
│   ├── Dockerfile
│   ├── main.go
│   └── go.mod
├── infra/                  # Main infrastructure
│   ├── main.tf
│   ├── modules/
│   │   ├── ec2/           # EC2 instance + security group
│   │   ├── ecr/           # ECR repository
│   │   ├── iam/           # EC2 IAM role + policies
│   │   └── config/        # SSM Parameter Store
│   └── init/              # Bootstrap (state backend + GitHub OIDC)
│       ├── main.tf
│       ├── state.tf       # S3 bucket + DynamoDB for state
│       └── github-oidc.tf # GitHub Actions OIDC provider
└── README.md
```

---

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Docker (for local testing)
- A GitHub repository

---

## Setup Guide

### Phase 1: Bootstrap (One-Time Setup)

The bootstrap creates the Terraform state backend (S3 + DynamoDB) and GitHub Actions OIDC provider. This is a chicken-and-egg situation: we need an S3 bucket for state, but we're creating it with Terraform.

#### Step 1: Configure Variables

```bash
cd 01-ec2-with-ecr/infra/init
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
aws_region            = "eu-central-1"
state_bucket_name     = "your-unique-terraform-state-bucket"
state_lock_table_name = "your-terraform-state-lock"
role_name             = "github-actions-role"
policy_arn            = "arn:aws:iam::aws:policy/AdministratorAccess"
github_repo           = "your-username/your-repo"
branch                = "main"
```

#### Step 2: Initialize and Apply with Local State

First, **comment out** the backend block in `init/main.tf`:

```hcl
terraform {
  # backend "s3" {
  #   encrypt = true
  # }
}
```

Then run:
```bash
terraform init
terraform apply
```

This creates:
- S3 bucket for Terraform state (versioned, encrypted)
- DynamoDB table for state locking
- GitHub OIDC provider
- IAM role for GitHub Actions

#### Step 3: Create Backend Configuration

Create `backend.hcl` with values matching your `terraform.tfvars`:

```hcl
bucket         = "your-unique-terraform-state-bucket"
key            = "bootstrap/terraform.tfstate"
dynamodb_table = "your-terraform-state-lock"
region         = "eu-central-1"
encrypt        = true
```

#### Step 4: Migrate State to S3

Uncomment the backend block in `init/main.tf`:
```hcl
terraform {
  backend "s3" {
    encrypt = true
  }
}
```

Migrate the state:
```bash
terraform init -backend-config=backend.hcl -migrate-state
# Type "yes" when prompted
```

Your bootstrap state is now stored in S3.

---

### Phase 2: Deploy Main Infrastructure

#### Step 1: Configure Backend

```bash
cd 01-ec2-with-ecr/infra
cp backend.hcl.example backend.hcl
```

Edit `backend.hcl`:
```hcl
bucket         = "your-unique-terraform-state-bucket"
key            = "01-ec2-with-ecr/terraform.tfstate"
dynamodb_table = "your-terraform-state-lock"
region         = "eu-central-1"
encrypt        = true
```

#### Step 2: Initialize and Apply

```bash
terraform init -backend-config=backend.hcl
terraform apply
```

This creates:
- ECR repository
- EC2 instance with:
  - Docker installed
  - Nginx configured as reverse proxy (port 80 → 8080)
  - SSM Agent for remote management
- IAM role with ECR pull and SSM permissions
- Security group (ports 22, 80, 443, 8080)
- Parameter Store entry with instance ID

---

### Phase 3: Configure GitHub Actions

Add these secrets to your GitHub repository (Settings → Secrets → Actions):

| Secret | Description | Example |
|--------|-------------|---------|
| `AWS_GHA_ROLE_ARN` | IAM role ARN for GitHub Actions | `arn:aws:iam::123456789:role/github-actions-role` |
| `AWS_REGION` | AWS region | `eu-central-1` |
| `AWS_ACCOUNT_ID` | Your AWS account ID | `123456789012` |
| `ECR_REPO` | ECR repository name | `ecr-repository` |
| `TF_BACKEND_BUCKET` | Terraform state bucket | `your-terraform-state-bucket` |
| `TF_BACKEND_KEY` | State file key | `01-ec2-with-ecr/terraform.tfstate` |
| `TF_BACKEND_DYNAMODB_TABLE` | DynamoDB lock table | `your-terraform-state-lock` |
| `TF_BACKEND_REGION` | State bucket region | `eu-central-1` |

---

## How It Works

### GitHub Actions Workflow

The workflow (`.github/workflows/01-ec2-with-ecr.yml`) has 4 jobs:

1. **changes**: Detects which files changed (infra vs app)
2. **terraform**: Runs `terraform apply` if infrastructure changed
3. **build-and-push**: Builds Docker image and pushes to ECR if app changed
4. **deploy**: Deploys to EC2 via SSM if app changed

```yaml
on:
  push:
    branches: [main]
    paths:
      - "01-ec2-with-ecr/**"
```

### Security Model

**GitHub Actions → AWS (OIDC)**
- No long-lived credentials stored
- Uses OpenID Connect for authentication
- Role can only be assumed by your specific repo/branch

**EC2 → ECR (IAM Role)**
- Instance profile attached to EC2
- Minimal permissions: only pull from specific ECR repo

**Deployment (SSM)**
- No SSH keys required
- Commands sent via AWS Systems Manager
- Instance ID stored in Parameter Store

### EC2 Configuration

The user-data script configures:
1. **Nginx** as reverse proxy (port 80 → 8080)
2. **Docker** for running containers
3. **AWS CLI** for ECR authentication

---

## Manual Operations

### Deploy Manually

```bash
# Get instance ID
INSTANCE_ID=$(aws ssm get-parameter \
  --name "/cloud-lab/01-ec2-with-ecr/ec2_instance_id" \
  --query "Parameter.Value" --output text)

# Deploy via SSM
aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=[
    "docker stop app || true",
    "docker rm app || true",
    "aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com",
    "docker pull YOUR_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/ecr-repository:latest",
    "docker run -d --name app -p 8080:8080 --restart unless-stopped YOUR_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/ecr-repository:latest"
  ]'
```

### Connect to EC2

```bash
aws ssm start-session --target $INSTANCE_ID
```

### Check Logs

```bash
# User-data execution log
sudo cat /var/log/user-data.log

# Nginx logs
sudo tail -f /var/log/nginx/error.log

# Docker container logs
docker logs app
```

---

## Troubleshooting

### Nginx shows default page instead of app
1. Check if container is running: `docker ps`
2. Check nginx config: `cat /etc/nginx/sites-enabled/reverse-proxy`
3. Test nginx config: `sudo nginx -t`
4. Restart nginx: `sudo systemctl restart nginx`

### GitHub Actions fails with OIDC error
1. Verify `github_repo` in terraform.tfvars matches your repo
2. Ensure the branch name matches
3. Check the IAM role trust policy

### Terraform state issues
1. Ensure S3 bucket and DynamoDB table exist
2. Verify backend.hcl values match actual resource names
3. Run `terraform init -reconfigure` if backend changed

---

## Production Considerations

To make this production-ready, consider:

- [ ] **HTTPS**: Add SSL certificate (ACM + ALB or Let's Encrypt)
- [ ] **Auto Scaling**: Replace single EC2 with ASG
- [ ] **Load Balancer**: Add ALB for high availability
- [ ] **Private Subnets**: Move EC2 to private subnet with NAT Gateway
- [ ] **Secrets Management**: Use AWS Secrets Manager for app secrets
- [ ] **Monitoring**: Add CloudWatch alarms and dashboards
- [ ] **Logging**: Centralize logs with CloudWatch Logs
- [ ] **Backup**: Enable automated EBS snapshots
- [ ] **Multi-AZ**: Deploy across availability zones
- [ ] **Blue/Green Deployment**: Implement zero-downtime deploys

---
