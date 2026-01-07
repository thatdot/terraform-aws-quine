# Terraform Beginner's Guide & Repository Walkthrough

This guide will teach you Terraform fundamentals and explain how the files in this repository work together to deploy an ECS Fargate service on AWS.

---

## Table of Contents

1. [What is Terraform?](#what-is-terraform)
2. [Core Concepts](#core-concepts)
3. [Basic Syntax](#basic-syntax)
4. [File Structure Overview](#file-structure-overview)
5. [This Repository Explained](#this-repository-explained)
6. [How the Files Connect](#how-the-files-connect)
7. [Common Commands](#common-commands)
8. [Reading Terraform Like a Pro](#reading-terraform-like-a-pro)

---

## What is Terraform?

Terraform is an **Infrastructure as Code (IaC)** tool that lets you define cloud resources in human-readable configuration files. Instead of clicking around in the AWS Console, you write code that describes what you want, and Terraform creates it for you.

### Key Benefits

| Benefit | Description |
|---------|-------------|
| **Declarative** | You describe the *end state*, not the steps to get there |
| **Version Control** | Infrastructure changes are tracked in git like any code |
| **Reproducible** | Same config = same infrastructure every time |
| **Multi-Cloud** | Works with AWS, Azure, GCP, and hundreds of other providers |

### How Terraform Works

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   .tf Files     │────▶│    Terraform    │────▶│   AWS/Cloud     │
│  (Your Config)  │     │    (Engine)     │     │  (Real Infra)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                               │
                               ▼
                        ┌─────────────────┐
                        │  State File     │
                        │ (tracks what    │
                        │  was created)   │
                        └─────────────────┘
```

---

## Core Concepts

### 1. Providers

Providers are plugins that let Terraform interact with cloud platforms or services.

```hcl
provider "aws" {
  region = "us-west-2"
}
```

Think of providers as **drivers** - you need the AWS driver to talk to AWS.

### 2. Resources

Resources are the actual infrastructure components you want to create.

```hcl
resource "aws_instance" "web_server" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
}
```

The format is: `resource "<provider>_<type>" "<your_name>"`

### 3. Variables

Variables make your configuration reusable and flexible.

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
```

### 4. Outputs

Outputs expose information after Terraform runs.

```hcl
output "server_ip" {
  value = aws_instance.web_server.public_ip
}
```

### 5. Data Sources

Data sources let you **read** existing resources (not create them).

```hcl
data "aws_vpc" "default" {
  default = true
}
```

### 6. State

Terraform keeps track of what it created in a **state file**. This is how it knows what exists and what needs to change.

---

## Basic Syntax

### HCL (HashiCorp Configuration Language)

Terraform uses HCL, which looks like this:

```hcl
# This is a comment

block_type "label1" "label2" {
  argument1 = "value1"
  argument2 = 123
  argument3 = true

  nested_block {
    nested_arg = "nested_value"
  }
}
```

### Common Patterns

```hcl
# Strings
name = "my-resource"

# Numbers
count = 3

# Booleans
enabled = true

# Lists
subnets = ["subnet-1", "subnet-2", "subnet-3"]

# Maps
tags = {
  Name        = "my-resource"
  Environment = "dev"
}

# References to other resources
vpc_id = aws_vpc.main.id
#        └─type─┘ └name┘ └attribute┘

# References to variables
region = var.aws_region

# References to data sources
vpc_id = data.aws_vpc.default.id
```

---

## File Structure Overview

Terraform loads **all `.tf` files** in a directory as one configuration. The file names are for human organization - Terraform doesn't care what you call them.

### Standard File Naming Convention

| File | Purpose |
|------|---------|
| `terraform.tf` | Terraform settings, required providers, backend config |
| `providers.tf` | Provider configurations |
| `variables.tf` | Input variable declarations |
| `outputs.tf` | Output value declarations |
| `main.tf` | Primary resources (or split into logical files) |
| `*.auto.tfvars` | Variable values (auto-loaded) |
| `terraform.tfvars` | Variable values (auto-loaded) |

---

## This Repository Explained

Let's walk through each file in this repository and understand what it does.

### File: `terraform.tf`

**Purpose:** Configures Terraform itself and the AWS provider.

```hcl
terraform {
  required_version = ">= 1.0"      # Minimum Terraform version

  required_providers {
    aws = {
      source  = "hashicorp/aws"    # Where to download the provider
      version = "~> 5.0"           # Provider version constraint
    }
  }
}

provider "aws" {
  region = var.aws_region          # Which AWS region to use

  default_tags {                   # Tags applied to ALL resources
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
```

**Key Points:**
- `required_version` ensures everyone uses a compatible Terraform version
- `~> 5.0` means "any 5.x version" (5.0, 5.1, 5.80, but not 6.0)
- `default_tags` automatically tags every AWS resource created

---

### File: `variables.tf`

**Purpose:** Declares all input variables - the "parameters" of your infrastructure.

```hcl
variable "aws_region" {
  description = "AWS region for resources"    # Human-readable explanation
  type        = string                        # Data type validation
  default     = "us-west-2"                   # Default if not provided
}

variable "container_cpu" {
  description = "CPU units for the container (1024 = 1 vCPU)"
  type        = number
  default     = 2048
}
```

**All Variables in This Repo:**

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | string | `us-west-2` | AWS region |
| `project_name` | string | `thatdot-ecs` | Used for naming resources |
| `environment` | string | `dev` | Environment tag |
| `cluster_name` | string | `thatdot-ecs-cluster` | ECS cluster name |
| `service_name` | string | `thatdot-ecs-service` | ECS service name |
| `container_name` | string | `quine` | Container name in task |
| `container_image` | string | `thatdot/quine:latest` | Docker image to run |
| `container_port` | number | `8080` | Port the app listens on |
| `container_cpu` | number | `2048` | CPU units (2 vCPU) |
| `container_memory` | number | `4096` | Memory in MB (4 GB) |
| `desired_count` | number | `1` | Number of tasks to run |
| `health_check_path` | string | `/api/v1/liveness` | ALB health check endpoint |

---

### File: `terraform.tfvars`

**Purpose:** Provides actual values for variables (overrides defaults).

```hcl
aws_region   = "us-west-2"
project_name = "thatdot-ecs"
environment  = "dev"
# ... more values
```

**How Variable Values Are Resolved (Priority Order):**

1. `-var` command line flag (highest priority)
2. `-var-file` command line flag
3. `*.auto.tfvars` files
4. `terraform.tfvars`
5. Environment variables (`TF_VAR_name`)
6. `default` in variable declaration (lowest priority)

---

### File: `security_groups.tf`

**Purpose:** Defines network access rules (firewalls) for the ALB and ECS tasks.

```hcl
# First, get a reference to the default VPC
data "aws_vpc" "default" {
  default = true
}

# Security Group for the Application Load Balancer
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = data.aws_vpc.default.id    # Reference to data source

  # Inbound rule: Allow HTTP from anywhere
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]    # 0.0.0.0/0 = the entire internet
  }

  # Outbound rule: Allow all traffic out
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"             # -1 = all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for ECS Tasks (containers)
resource "aws_security_group" "ecs_tasks" {
  name   = "${var.project_name}-ecs-tasks-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description     = "Allow traffic from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]  # Only from ALB!
  }
  # ...
}
```

**Key Points:**
- `data "aws_vpc"` reads the existing default VPC (doesn't create one)
- `${var.project_name}` is string interpolation
- The ECS security group only allows traffic from the ALB security group (not the internet directly)

---

### File: `iam.tf`

**Purpose:** Defines IAM roles that give ECS permissions to do things.

```hcl
# Role that ECS uses to pull images and write logs
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"

  # Trust policy: Who can assume this role?
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"    # ECS can assume this role
        }
      }
    ]
  })
}

# Attach AWS managed policy to the role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
```

**Two Roles Explained:**

| Role | Purpose | Used By |
|------|---------|---------|
| `ecs_task_execution_role` | Pull container images, push logs to CloudWatch | ECS agent (infrastructure) |
| `ecs_task_role` | Permissions for your application code | Your container (application) |

---

### File: `alb.tf`

**Purpose:** Creates the Application Load Balancer that routes traffic to containers.

```hcl
# Get subnet IDs from the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]    # Reference to security_groups.tf
  }
}

# The Load Balancer itself
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false                        # Internet-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]  # From security_groups.tf
  subnets            = data.aws_subnets.default.ids
}

# Target Group: Where to send traffic
resource "aws_lb_target_group" "main" {
  name        = "${var.project_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"              # For Fargate, must be "ip" not "instance"

  health_check {
    path     = var.health_check_path    # /api/v1/liveness
    matcher  = "200-299"                # Success = any 2xx response
  }
}

# Listener: What port to accept traffic on
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
```

**Traffic Flow:**
```
Internet → ALB (port 80) → Target Group → ECS Tasks (port 8080)
```

---

### File: `ecs.tf`

**Purpose:** Creates the ECS cluster, task definition, and service.

```hcl
# CloudWatch Log Group for container logs
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

# ECS Cluster: Logical grouping of services
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Task Definition: Blueprint for your container
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"          # Required for Fargate
  requires_compatibilities = ["FARGATE"]       # Serverless containers
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  # Container configuration as JSON
  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.container_image         # thatdot/quine:latest
      cpu       = var.container_cpu
      memory    = var.container_memory
      essential = true                        # Task fails if this container fails

      portMappings = [
        {
          containerPort = var.container_port  # 8080
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# ECS Service: Keeps your tasks running
resource "aws_ecs_service" "main" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count         # How many containers to run
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb_listener.main,
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy
  ]
}
```

**ECS Hierarchy:**
```
Cluster
  └── Service (keeps N tasks running, handles deployments)
        └── Task (running instance of a task definition)
              └── Container(s) (your actual application)
```

---

### File: `outputs.tf`

**Purpose:** Exposes useful information after `terraform apply`.

```hcl
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_url" {
  description = "URL of the Application Load Balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}
```

After running `terraform apply`, you'll see:
```
Outputs:

alb_dns_name = "thatdot-ecs-alb-123456789.us-west-2.elb.amazonaws.com"
alb_url = "http://thatdot-ecs-alb-123456789.us-west-2.elb.amazonaws.com"
ecs_cluster_name = "thatdot-ecs-cluster"
```

---

## How the Files Connect

### Dependency Graph

Terraform automatically figures out the order to create resources based on references:

```
                    ┌─────────────────┐
                    │  variables.tf   │
                    │  (inputs)       │
                    └────────┬────────┘
                             │ var.* references
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│ security_     │    │    iam.tf     │    │  terraform.tf │
│ groups.tf     │    │               │    │  (provider)   │
└───────┬───────┘    └───────┬───────┘    └───────────────┘
        │                    │
        │ aws_security_      │ aws_iam_role.*
        │ group.*.id         │
        ▼                    ▼
┌───────────────────────────────────────┐
│              alb.tf                   │
│  (needs security groups)              │
└───────────────────┬───────────────────┘
                    │
                    │ aws_lb_target_group.main.arn
                    │ aws_lb_listener.main (depends_on)
                    ▼
┌───────────────────────────────────────┐
│              ecs.tf                   │
│  (needs ALB, IAM, security groups)    │
└───────────────────┬───────────────────┘
                    │
                    │ Resource attributes
                    ▼
┌───────────────────────────────────────┐
│            outputs.tf                 │
│  (exposes created resource info)      │
└───────────────────────────────────────┘
```

### Reference Chain Example

Let's trace how `var.container_port` flows through the configuration:

```
variables.tf:    variable "container_port" { default = 8080 }
                              │
terraform.tfvars:             │ (can override)
                              ▼
security_groups.tf:  from_port = var.container_port
                              │
alb.tf:              port = var.container_port
                              │
ecs.tf:              containerPort = var.container_port
                              │
                     container_port = var.container_port (in load_balancer block)
```

One change to the variable updates it everywhere!

---

## Common Commands

### Workflow Commands

```bash
# Initialize - downloads providers, sets up backend
terraform init

# Format - auto-formats all .tf files
terraform fmt

# Validate - checks syntax without accessing cloud
terraform validate

# Plan - shows what will change (dry run)
terraform plan

# Apply - creates/updates infrastructure
terraform apply

# Destroy - deletes all infrastructure
terraform destroy
```

### Inspection Commands

```bash
# Show current state
terraform show

# List resources in state
terraform state list

# Show specific resource details
terraform state show aws_ecs_cluster.main

# Show outputs
terraform output
terraform output alb_url
```

### Common Flags

```bash
# Auto-approve (skip confirmation)
terraform apply -auto-approve

# Target specific resource
terraform apply -target=aws_ecs_service.main

# Use different variable file
terraform apply -var-file="prod.tfvars"

# Pass variable directly
terraform apply -var="desired_count=3"
```

---

## Reading Terraform Like a Pro

### Quick Reference Patterns

| Pattern | Meaning |
|---------|---------|
| `var.name` | Reference to a variable |
| `aws_resource.name.attribute` | Reference to a resource's attribute |
| `data.aws_resource.name.attribute` | Reference to a data source |
| `local.name` | Reference to a local value |
| `module.name.output` | Reference to a module output |
| `"${var.name}-suffix"` | String interpolation |
| `count = 3` | Create 3 copies of this resource |
| `for_each = var.map` | Create one resource per map entry |
| `depends_on = [...]` | Explicit dependency (usually automatic) |

### Reading Strategy

1. **Start with `variables.tf`** - understand the inputs
2. **Scan `terraform.tf`** - see what providers are used
3. **Find the "main" resources** - usually in `main.tf` or domain-specific files
4. **Follow the references** - trace `resource_type.name.attribute` references
5. **Check `outputs.tf`** - see what's exposed

### Mental Model

Think of Terraform like a recipe:
- **Variables** = Ingredients list (what you need to provide)
- **Resources** = Recipe steps (what gets created)
- **Data Sources** = Looking something up (checking what already exists)
- **Outputs** = Plating instructions (what you get at the end)
- **State** = Your kitchen notebook (tracking what you've made)

---

## Architecture This Repo Creates

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                               │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                      Default VPC                          │  │
│  │                                                           │  │
│  │   ┌─────────────────────────────────────────────────┐    │  │
│  │   │              Public Subnets                      │    │  │
│  │   │                                                  │    │  │
│  │   │  ┌──────────────────────────────────────────┐   │    │  │
│  │   │  │     Application Load Balancer            │   │    │  │
│  │   │  │     (port 80, internet-facing)           │   │    │  │
│  │   │  │     Security Group: alb-sg               │   │    │  │
│  │   │  └──────────────────┬───────────────────────┘   │    │  │
│  │   │                     │                            │    │  │
│  │   │                     ▼                            │    │  │
│  │   │  ┌──────────────────────────────────────────┐   │    │  │
│  │   │  │         Target Group (port 8080)         │   │    │  │
│  │   │  └──────────────────┬───────────────────────┘   │    │  │
│  │   │                     │                            │    │  │
│  │   │                     ▼                            │    │  │
│  │   │  ┌──────────────────────────────────────────┐   │    │  │
│  │   │  │           ECS Fargate Service            │   │    │  │
│  │   │  │     Security Group: ecs-tasks-sg         │   │    │  │
│  │   │  │  ┌────────────────────────────────────┐  │   │    │  │
│  │   │  │  │      Task (thatdot/quine:8080)     │  │   │    │  │
│  │   │  │  │      - 2 vCPU, 4 GB RAM            │  │   │    │  │
│  │   │  │  │      - Logs → CloudWatch           │  │   │    │  │
│  │   │  │  └────────────────────────────────────┘  │   │    │  │
│  │   │  └──────────────────────────────────────────┘   │    │  │
│  │   └──────────────────────────────────────────────────┘    │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐                      │
│  │ IAM Roles       │  │ CloudWatch Logs │                      │
│  │ - execution     │  │ /ecs/thatdot-   │                      │
│  │ - task          │  │     ecs         │                      │
│  └─────────────────┘  └─────────────────┘                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Next Steps

1. **Run `terraform init`** to initialize the configuration
2. **Run `terraform plan`** to see what would be created
3. **Study the plan output** - it shows exactly what Terraform will do
4. **Experiment!** Change a variable and run `plan` again to see the difference

Happy Terraforming!
