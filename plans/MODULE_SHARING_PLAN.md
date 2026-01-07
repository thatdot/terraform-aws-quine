# Terraform Module Sharing Plan

## Goal

Make the ECS Quine Terraform configuration easily consumable by others, similar to how Helm charts allow users to customize deployments via `values.yaml`.

---

## Research Summary

### How Terraform Modules Compare to Helm Charts

| Aspect | Helm Charts | Terraform Modules |
|--------|-------------|-------------------|
| Package Format | Chart archive (.tgz) | Directory with .tf files |
| Values File | `values.yaml` | `terraform.tfvars` |
| Registry | Helm Hub / OCI registries | Terraform Registry / Git repos |
| Installation | `helm install myapp ./chart -f values.yaml` | `terraform apply -var-file=prod.tfvars` |

**The Terraform equivalent workflow:**
```bash
# User creates main.tf calling your module
module "quine" {
  source  = "your-username/ecs-quine/aws"
  version = "1.0.0"

  project_name = var.project_name
  environment  = var.environment
}

# User creates terraform.tfvars (like values.yaml)
project_name = "my-quine"
environment  = "production"

# User runs
terraform init && terraform apply
```

---

## Distribution Options

### Option A: Public Terraform Registry (Recommended)

**Pros:**
- Official discovery mechanism
- Version constraints with `version = "~> 1.0"`
- Automatic documentation generation
- Free for public modules

**Cons:**
- Requires public GitHub repository
- Must follow naming convention

**User consumption:**
```hcl
module "quine" {
  source  = "your-username/ecs-quine/aws"
  version = "1.0.0"

  project_name    = "my-quine"
  container_image = "thatdot/quine:1.5.0"
}
```

### Option B: GitHub Repository (Direct)

**Pros:**
- Works with private repos (SSH auth)
- No registry signup required
- Immediate availability

**Cons:**
- Less discoverable
- No built-in documentation hosting

**User consumption:**
```hcl
module "quine" {
  source = "github.com/your-org/terraform-aws-ecs-quine?ref=v1.0.0"

  project_name    = "my-quine"
  container_image = "thatdot/quine:1.5.0"
}
```

### Option C: HCP Terraform Private Registry

**Pros:**
- Access control
- Works with private VCS
- Enterprise features

**Cons:**
- Requires HCP Terraform account
- May have cost implications at scale

---

## Implementation Plan

### Phase 1: Repository Restructure

**1.1 Rename repository**

Current: `temp-ecs-terraform`
Required: `terraform-aws-ecs-quine`

The naming convention `terraform-<PROVIDER>-<NAME>` is mandatory for Terraform Registry.

**1.2 Reorganize file structure**

```
terraform-aws-ecs-quine/
├── main.tf              # Entry point (or keep separate files)
├── variables.tf         # Input variables (enhance with validation)
├── outputs.tf           # Output declarations
├── versions.tf          # NEW: Provider/Terraform version constraints
├── README.md            # Enhanced documentation
├── LICENSE              # NEW: Add license file
├── examples/            # NEW: Usage examples
│   ├── basic/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── complete/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars.example
│       ├── outputs.tf
│       └── README.md
└── modules/             # OPTIONAL: Submodules for flexibility
    ├── cluster/
    ├── service/
    └── alb/
```

**1.3 Create versions.tf**

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
```

**1.4 Remove files that shouldn't be shared**

- `terraform.tfstate` - Never commit state files
- `terraform.tfstate.backup` - Never commit state files
- `terraform.tfvars` - Keep as `.example` only; users provide their own
- `.terraform/` directory - Add to .gitignore

**1.5 Add .gitignore**

```gitignore
# Terraform
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
!*.tfvars.example
.terraform.lock.hcl

# IDE
.idea/
.vscode/
*.swp
```

---

### Phase 2: Enhance Variables

**2.1 Add validation rules**

```hcl
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "container_cpu" {
  description = "CPU units for the container"
  type        = number
  default     = 2048

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.container_cpu)
    error_message = "Container CPU must be a valid Fargate CPU value: 256, 512, 1024, 2048, or 4096."
  }
}

variable "container_image" {
  description = "Docker image to run (e.g., thatdot/quine:latest)"
  type        = string
  default     = "thatdot/quine:latest"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9._/-]+:[a-zA-Z0-9._-]+$", var.container_image))
    error_message = "Container image must be a valid Docker image reference with tag."
  }
}
```

**2.2 Add new flexibility variables**

```hcl
variable "vpc_id" {
  description = "VPC ID. If not provided, uses the default VPC."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for the ALB and ECS tasks. If not provided, uses default VPC subnets."
  type        = list(string)
  default     = null
}

variable "enable_https" {
  description = "Enable HTTPS listener (requires certificate_arn)"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN of ACM certificate for HTTPS"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "container_environment" {
  description = "Additional environment variables for the container"
  type        = list(object({
    name  = string
    value = string
  }))
  default = []
}
```

---

### Phase 3: Documentation

**3.1 Enhance README.md**

```markdown
# Terraform AWS ECS Quine Module

Deploys [Quine](https://quine.io/) streaming graph on AWS ECS Fargate with an Application Load Balancer.

## Features

- ECS Fargate cluster (serverless containers)
- Application Load Balancer with health checks
- CloudWatch logging with configurable retention
- IAM roles with least-privilege permissions
- Optional HTTPS support
- Configurable CPU, memory, and task count

## Quick Start

```hcl
module "quine" {
  source  = "your-username/ecs-quine/aws"
  version = "1.0.0"

  project_name = "my-quine"
  environment  = "dev"
}

output "url" {
  value = module.quine.alb_url
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name for resource naming | `string` | n/a | yes |
| environment | Environment (dev/staging/prod) | `string` | `"dev"` | no |
| container_image | Docker image reference | `string` | `"thatdot/quine:latest"` | no |
| container_cpu | CPU units (256-4096) | `number` | `2048` | no |
| container_memory | Memory in MB | `number` | `4096` | no |
| desired_count | Number of tasks | `number` | `1` | no |
| vpc_id | Custom VPC ID | `string` | `null` | no |
| subnet_ids | Custom subnet IDs | `list(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_dns_name | DNS name of the load balancer |
| alb_url | Full URL to access Quine |
| ecs_cluster_arn | ARN of the ECS cluster |
| ecs_service_name | Name of the ECS service |

## Examples

- [Basic deployment](examples/basic/) - Minimal configuration using defaults
- [Complete deployment](examples/complete/) - Production setup with custom VPC

## License

MIT
```

**3.2 Create example configurations**

`examples/basic/main.tf`:
```hcl
provider "aws" {
  region = "us-west-2"
}

module "quine" {
  source = "../../"

  project_name = "quine-basic"
  environment  = "dev"
}

output "url" {
  description = "URL to access Quine"
  value       = module.quine.alb_url
}
```

`examples/complete/main.tf`:
```hcl
provider "aws" {
  region = var.aws_region
}

module "quine" {
  source = "../../"

  project_name      = var.project_name
  environment       = var.environment
  container_image   = var.container_image
  container_cpu     = var.container_cpu
  container_memory  = var.container_memory
  desired_count     = var.desired_count
  health_check_path = var.health_check_path
}

output "url" {
  value = module.quine.alb_url
}
```

`examples/complete/terraform.tfvars.example`:
```hcl
# AWS Configuration
aws_region   = "us-west-2"
project_name = "quine-prod"
environment  = "prod"

# Container Configuration
container_image  = "thatdot/quine:1.5.0"
container_cpu    = 4096
container_memory = 8192
desired_count    = 2

# Health Check
health_check_path = "/api/v1/liveness"
```

---

### Phase 4: Publish

**4.1 Create initial release**

```bash
git add .
git commit -m "Prepare module for public release"
git tag -a v1.0.0 -m "Initial release"
git push origin main --tags
```

**4.2 Publish to Terraform Registry**

1. Go to https://registry.terraform.io
2. Sign in with GitHub
3. Click "Publish" → "Module"
4. Select your repository
5. Module publishes within seconds

**4.3 Announce and document**

- Update any internal documentation
- Create a blog post or announcement if appropriate
- Add badge to README: `[![Terraform Registry](https://img.shields.io/badge/terraform-registry-blue)](https://registry.terraform.io/modules/your-username/ecs-quine/aws)`

---

## User Experience After Implementation

Users will be able to deploy Quine with minimal configuration:

**Step 1: Create `main.tf`**
```hcl
module "quine" {
  source  = "your-username/ecs-quine/aws"
  version = "1.0.0"

  project_name = "my-quine"
}

output "url" {
  value = module.quine.alb_url
}
```

**Step 2: Create `terraform.tfvars` (optional customization)**
```hcl
project_name     = "my-quine"
environment      = "production"
container_cpu    = 4096
container_memory = 8192
desired_count    = 2
```

**Step 3: Deploy**
```bash
terraform init
terraform apply
```

This matches the Helm experience of:
```bash
helm install my-release chart/ -f values.yaml
```

---

## Checklist

- [ ] Rename repository to `terraform-aws-ecs-quine`
- [ ] Create `versions.tf` with provider constraints
- [ ] Add `.gitignore` for state files
- [ ] Remove `terraform.tfstate` and `terraform.tfstate.backup`
- [ ] Rename `terraform.tfvars` to `terraform.tfvars.example`
- [ ] Add validation rules to `variables.tf`
- [ ] Add flexibility variables (vpc_id, subnet_ids, etc.)
- [ ] Enhance `README.md` with inputs/outputs tables
- [ ] Create `examples/basic/` directory
- [ ] Create `examples/complete/` directory
- [ ] Add `LICENSE` file
- [ ] Create git tag `v1.0.0`
- [ ] Publish to Terraform Registry

---

## References

- [Terraform Registry - Publishing Modules](https://developer.hashicorp.com/terraform/registry/modules/publish)
- [Terraform Module Sources](https://developer.hashicorp.com/terraform/language/modules/sources)
- [Standard Module Structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure)
- [Input Variable Validation](https://developer.hashicorp.com/terraform/language/values/variables#custom-validation-rules)
