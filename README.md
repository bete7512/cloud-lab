# Cloud Lab

A collection of infrastructure-as-code projects demonstrating AWS deployments using Terraform and CI/CD pipelines.

## Projects

### [01-ec2-with-ecr](./01-ec2-with-ecr/README.md)

**Deploy Go App with Terraform & GitHub Actions**

A complete infrastructure-as-code solution for deploying a containerized Go application to AWS EC2 using Terraform and GitHub Actions CI/CD.

**Architecture:**
```
User Push → GitHub Actions (CI/CD) → ECR (Container Registry) → EC2 (Docker + Nginx)
                                              ↓
                                         SSM (Deploy)
```

**Key Components:**
- EC2 instance with Docker and Nginx reverse proxy
- ECR repository for container images
- GitHub Actions workflow with OIDC authentication
- IAM roles for secure ECR access and SSM deployment
- Terraform remote state with S3 and DynamoDB

**Technologies:** Terraform, AWS (EC2, ECR, IAM, SSM, S3, DynamoDB), GitHub Actions with aws oidc authentication, Docker, Nginx, Go



## Getting Started

Each project has its own setup instructions. Navigate to the project folder and follow the README for detailed setup and deployment steps.

## Prerequisites

- AWS CLI configured
- Terraform >= 1.0
- Docker (for local testing)
- GitHub account and repository

## License

MIT
