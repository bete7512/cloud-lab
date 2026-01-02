# Cloud Lab

Infrastructure-as-code projects for AWS deployments using Terraform and CI/CD.

## Projects

---------------------------------------------------------------------------------------------------------------------------
### [01-ec2-with-ecr](./01-ec2-with-ecr/README.md)

Deploy a Go app to EC2 with automated CI/CD via GitHub Actions.

**Architecture:**
```
User Push → GitHub Actions → ECR → EC2 (Docker + Nginx)
                    ↓
                SSM Deploy
```

**Stack:** Terraform, AWS (EC2, ECR, IAM, SSM, S3, DynamoDB), GitHub Actions (OIDC), Docker, Nginx, Go

---------------------------------------------------------------------------------------------------------------------------


Each project has its own setup guide. Check the project's README for details.

**Prerequisites:**
- AWS CLI configured
- Terraform >= 1.0
- Docker
- GitHub repository
