# -----------------------------------------------------------------------------
# Complete Example - Quine on ECS Fargate with Custom VPC and HTTPS
# -----------------------------------------------------------------------------
# This example demonstrates a production-ready deployment of Quine with:
# - Custom VPC and subnets
# - HTTPS with ACM certificate
# - Custom container configuration
# - Environment variables and secrets
# - Multiple task instances for high availability
#
# Usage:
#   # Copy the example tfvars file and customize
#   cp terraform.tfvars.example terraform.tfvars
#
#   # Edit terraform.tfvars with your values
#
#   terraform init
#   terraform plan
#   terraform apply
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Configure the AWS provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Example     = "complete"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

# Look up existing VPC by tag (optional - remove if using vpc_id directly)
data "aws_vpc" "selected" {
  count = var.vpc_name != null ? 1 : 0

  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Look up subnets by tag (optional - remove if using subnet_ids directly)
data "aws_subnets" "selected" {
  count = var.subnet_tag_filter != null ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id != null ? var.vpc_id : data.aws_vpc.selected[0].id]
  }

  filter {
    name   = "tag:Name"
    values = [var.subnet_tag_filter]
  }
}

# -----------------------------------------------------------------------------
# Module Deployment
# -----------------------------------------------------------------------------

module "quine" {
  source = "../../"

  # Project identification
  project_name = var.project_name
  environment  = var.environment

  # Network configuration
  # Priority: explicit subnet_ids > subnet lookup > default VPC
  vpc_id = coalesce(
    var.vpc_id,
    var.vpc_name != null ? data.aws_vpc.selected[0].id : null
  )
  subnet_ids = coalesce(
    var.subnet_ids,
    var.subnet_tag_filter != null ? data.aws_subnets.selected[0].ids : null
  )
  assign_public_ip = var.assign_public_ip

  # ECS cluster configuration
  cluster_name              = var.cluster_name
  enable_container_insights = var.enable_container_insights

  # ECS service configuration
  service_name  = var.service_name
  desired_count = var.desired_count

  # Container configuration
  container_name   = var.container_name
  container_image  = var.container_image
  container_port   = var.container_port
  container_cpu    = var.container_cpu
  container_memory = var.container_memory

  # Environment variables
  container_environment = var.container_environment

  # Secrets (from SSM Parameter Store or Secrets Manager)
  container_secrets = var.container_secrets

  # Load balancer configuration
  internal_alb               = var.internal_alb
  health_check_path          = var.health_check_path
  health_check_interval      = var.health_check_interval
  enable_deletion_protection = var.enable_deletion_protection

  # HTTPS configuration
  enable_https    = var.enable_https
  certificate_arn = var.certificate_arn
  ssl_policy      = var.ssl_policy

  # Logging
  log_retention_days = var.log_retention_days

  # Security
  alb_ingress_cidr_blocks = var.alb_ingress_cidr_blocks

  # Additional IAM policies
  additional_task_role_policy_arns      = var.additional_task_role_policy_arns
  additional_execution_role_policy_arns = var.additional_execution_role_policy_arns

  # Custom tags
  tags = var.tags
}
