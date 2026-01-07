# Basic Example

This example demonstrates the simplest deployment of Quine on AWS ECS Fargate using the module with minimal configuration.

## What This Creates

- ECS Fargate cluster with Container Insights enabled
- ECS service running 1 Quine container
- Application Load Balancer (internet-facing)
- Security groups for ALB and ECS tasks
- CloudWatch log group for container logs
- IAM roles for task execution and runtime

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.5.0
- Default VPC available in the target region

## Usage

```bash
# Initialize Terraform
terraform init

# Preview the changes
terraform plan

# Deploy the infrastructure
terraform apply
```

## Accessing Quine

After deployment, the Quine web interface URL is displayed in the outputs:

```bash
terraform output url
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Customization

To customize the deployment, modify `main.tf` or create a `terraform.tfvars` file. See the [complete example](../complete/) for advanced configuration options.

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| N/A | This example uses hardcoded values | N/A | N/A |

## Outputs

| Name | Description |
|------|-------------|
| url | URL to access Quine web interface |
| alb_dns_name | DNS name of the Application Load Balancer |
| ecs_cluster_name | Name of the ECS cluster |
| ecs_service_name | Name of the ECS service |
| cloudwatch_log_group | CloudWatch log group name |
