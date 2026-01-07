# thatDot ECS Terraform Infrastructure

This Terraform project provisions an AWS ECS (Elastic Container Service) infrastructure with the following components:

- ECS Cluster running on Fargate (serverless)
- ECS Service running thatDot Quine
- Application Load Balancer (ALB)
- Security Groups for ALB and ECS tasks
- IAM roles for ECS task execution and container permissions
- CloudWatch Logs for container logging

## Prerequisites

1. AWS CLI installed and configured with credentials
2. Terraform installed (>= 1.0)
3. AWS account with appropriate permissions

## Project Structure

```
.
├── terraform.tf              # Provider and version configuration
├── variables.tf              # Input variable definitions
├── terraform.tfvars.example  # Example variable values
├── iam.tf             # IAM roles and policies
├── security_groups.tf # Security groups for ALB and ECS
├── alb.tf             # Application Load Balancer resources
├── ecs.tf             # ECS cluster, task definition, and service
├── outputs.tf         # Output values
└── README.md          # This file
```

## Deployment

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Review the Plan

```bash
terraform plan
```

### 3. Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### 4. Get the Application URL

After deployment completes, the ALB URL will be displayed in the outputs:

```bash
terraform output alb_url
```

Visit this URL in your browser to see the Quine UI.

## Customization

To customize the deployment, copy the example tfvars file and edit as needed:

```bash
cp terraform.tfvars.example terraform.tfvars
```

See `variables.tf` for all available options.

## Cleanup

To destroy all resources created by this module:

```bash
terraform destroy
```

Type `yes` when prompted to confirm.
