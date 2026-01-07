# Complete Example

This example demonstrates a production-ready deployment of Quine on AWS ECS Fargate with all available configuration options.

## Features Demonstrated

- Custom VPC and subnet configuration
- HTTPS with ACM certificate
- High availability with multiple task instances
- Custom container CPU/memory allocation
- Environment variables and secrets injection
- Restricted ALB access via CIDR blocks
- CloudWatch Container Insights
- ALB deletion protection
- Custom tagging strategy

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.5.0
- (For HTTPS) ACM certificate in the same region
- (Optional) Custom VPC with public subnets

## Usage

1. Copy the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your values:

```bash
# At minimum, set project_name
project_name = "my-quine-prod"

# For HTTPS, add certificate ARN
enable_https    = true
certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/..."
```

3. Deploy:

```bash
terraform init
terraform plan
terraform apply
```

## Network Configuration Options

### Option 1: Default VPC (Simplest)

Leave `vpc_id` and `subnet_ids` unset to use the default VPC:

```hcl
# No vpc_id or subnet_ids specified
project_name = "quine-prod"
```

### Option 2: Explicit VPC and Subnets

Specify VPC and subnet IDs directly:

```hcl
vpc_id     = "vpc-0123456789abcdef0"
subnet_ids = ["subnet-111", "subnet-222", "subnet-333"]
```

### Option 3: VPC Lookup by Name

Look up VPC by its Name tag:

```hcl
vpc_name          = "production-vpc"
subnet_tag_filter = "*-public-*"
```

## HTTPS Configuration

To enable HTTPS:

1. Create an ACM certificate for your domain
2. Configure the module:

```hcl
enable_https    = true
certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/..."
ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
```

3. (Optional) Create a Route53 alias record pointing to the ALB

## Secrets Management

Inject secrets from AWS Secrets Manager or SSM Parameter Store:

```hcl
container_secrets = [
  {
    name      = "DATABASE_PASSWORD"
    valueFrom = "arn:aws:secretsmanager:us-west-2:123456789012:secret:db-password"
  },
  {
    name      = "API_KEY"
    valueFrom = "arn:aws:ssm:us-west-2:123456789012:parameter/api-key"
  }
]
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Note: If `enable_deletion_protection = true`, you must first disable it in the AWS Console or set it to `false` and apply before destroying.

## Inputs

See `variables.tf` for the complete list of available inputs.

## Outputs

| Name | Description |
|------|-------------|
| url | URL to access Quine |
| alb_dns_name | ALB DNS name |
| alb_zone_id | ALB Route53 zone ID (for alias records) |
| ecs_cluster_name | ECS cluster name |
| ecs_cluster_arn | ECS cluster ARN |
| ecs_service_name | ECS service name |
| cloudwatch_log_group | CloudWatch log group |
| vpc_id | VPC ID |
| subnet_ids | Subnet IDs |
