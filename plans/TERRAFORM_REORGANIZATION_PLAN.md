# Terraform Repository Reorganization Plan

This document outlines best practices and a reorganization plan for persisting this Terraform ECS infrastructure in a public GitHub repository.

---

## Current State Assessment

### Existing Files
```
.
├── terraform.tf          # Provider and version configuration
├── variables.tf          # Input variable definitions
├── terraform.tfvars      # Variable values (contains real config!)
├── ecs.tf               # ECS cluster, task definition, service
├── alb.tf               # Application Load Balancer resources
├── iam.tf               # IAM roles and policies
├── security_groups.tf   # Security groups
├── outputs.tf           # Output values
├── README.md            # Documentation
├── terraform.tfstate    # STATE FILE - SECURITY RISK
└── terraform.tfstate.backup  # STATE BACKUP - SECURITY RISK
```

### Critical Issues Identified

| Issue | Severity | Risk |
|-------|----------|------|
| `terraform.tfstate` committed | **CRITICAL** | State files contain all resource attributes, potentially including secrets in plain text |
| `terraform.tfstate.backup` committed | **CRITICAL** | Same as above |
| `terraform.tfvars` with real values | **HIGH** | Exposes infrastructure configuration details |
| No `.gitignore` | **HIGH** | Nothing prevents accidental commits of sensitive files |
| Local state only | **MEDIUM** | No team collaboration, no state locking, data loss risk |

---

## Recommended Repository Structure

```
.
├── .gitignore                    # Git ignore rules (NEW)
├── .github/
│   └── workflows/
│       └── terraform.yml         # CI/CD validation (NEW)
├── README.md                     # Updated documentation
├── TERRAFORM_REORGANIZATION_PLAN.md  # This file
├── terraform.tf                  # Backend + required providers
├── providers.tf                  # Provider configurations (NEW - split from terraform.tf)
├── variables.tf                  # Input variable declarations
├── outputs.tf                    # Output declarations
├── ecs.tf                       # ECS resources
├── alb.tf                       # ALB resources
├── iam.tf                       # IAM resources
├── security_groups.tf           # Security group resources
├── terraform.tfvars.example     # Example variable values (NEW)
├── backend.hcl.example          # Example backend config (NEW)
└── .terraform.lock.hcl          # Provider lock file (commit this!)
```

---

## Action Items

### Phase 1: Security Fixes (Do First!)

#### 1.1 Create `.gitignore`

```gitignore
# Local .terraform directories
.terraform/
.terraform.lock.hcl

# Terraform state files - NEVER commit these
*.tfstate
*.tfstate.*
*.tfstate.backup

# Crash log files
crash.log
crash.*.log

# Exclude all .tfvars files containing actual values
*.tfvars
*.tfvars.json

# But DO track the example file
!*.tfvars.example

# Ignore override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Ignore CLI configuration files
.terraformrc
terraform.rc

# Ignore plan output files
*.tfplan
*.out

# Ignore backend configuration with secrets
backend.hcl

# IDE and editor files
.idea/
*.swp
*.swo
.vscode/
*.code-workspace

# OS files
.DS_Store
Thumbs.db
```

#### 1.2 Remove Sensitive Files from Git History

**Before making the repo public**, remove state files from git history:

```bash
# If not yet a git repo, simply delete the files
rm terraform.tfstate terraform.tfstate.backup

# If already a git repo with history, use git filter-repo (recommended)
# Install: pip install git-filter-repo
git filter-repo --path terraform.tfstate --invert-paths
git filter-repo --path terraform.tfstate.backup --invert-paths

# Or use BFG Repo-Cleaner
# https://rtyley.github.io/bfg-repo-cleaner/
```

#### 1.3 Create Example Variable File

Rename/copy `terraform.tfvars` to `terraform.tfvars.example` with sanitized values:

```hcl
# terraform.tfvars.example
# Copy this file to terraform.tfvars and customize for your environment
# NEVER commit terraform.tfvars to version control

# AWS Configuration
aws_region   = "us-west-2"
project_name = "my-ecs-project"
environment  = "dev"

# ECS Configuration
cluster_name     = "my-ecs-cluster"
service_name     = "my-ecs-service"
container_name   = "my-container"
container_image  = "your-org/your-image:latest"
container_port   = 8080
container_cpu    = 2048   # 2 vCPU
container_memory = 4096   # 4 GB
desired_count    = 1

# Health Check
health_check_path = "/health"
```

---

### Phase 2: Remote State Configuration

#### 2.1 Create S3 Backend Infrastructure

Create a separate bootstrap configuration or use AWS CLI:

```bash
# Create S3 bucket for state
aws s3api create-bucket \
  --bucket your-org-terraform-state \
  --region us-west-2 \
  --create-bucket-configuration LocationConstraint=us-west-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-org-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket your-org-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket your-org-terraform-state \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'
```

#### 2.2 Update `terraform.tf` with Backend Configuration

```hcl
terraform {
  required_version = ">= 1.0"

  backend "s3" {
    # Non-sensitive values can be in code
    key          = "ecs-fargate/terraform.tfstate"
    use_lockfile = true    # Modern S3-native locking (replaces DynamoDB)
    encrypt      = true

    # bucket and region provided via -backend-config
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

#### 2.3 Create `backend.hcl.example`

```hcl
# Backend Configuration Example
# Copy to backend.hcl and fill in your values
# NEVER commit backend.hcl to version control

bucket = "your-org-terraform-state"
region = "us-west-2"

# Optional: For cross-account access
# role_arn = "arn:aws:iam::ACCOUNT_ID:role/TerraformStateAccess"
```

#### 2.4 Migrate State to Remote

```bash
# Initialize with new backend
terraform init -backend-config=backend.hcl

# Terraform will ask to migrate existing state - answer 'yes'
```

---

### Phase 3: File Organization

#### 3.1 Split `terraform.tf` into Two Files

**terraform.tf** (backend and requirements):
```hcl
terraform {
  required_version = ">= 1.0"

  backend "s3" {
    key          = "ecs-fargate/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

**providers.tf** (provider configuration):
```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
```

#### 3.2 Optional: Consolidate Data Sources

Move data sources from `alb.tf` and `security_groups.tf` to a `data.tf` file:

```hcl
# data.tf
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
```

---

### Phase 4: CI/CD Setup

#### 4.1 Create GitHub Actions Workflow

Create `.github/workflows/terraform.yml`:

```yaml
name: Terraform CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.x

      - name: Terraform Format Check
        run: terraform fmt -check -recursive

      - name: Terraform Init
        run: terraform init -backend=false

      - name: Terraform Validate
        run: terraform validate

  security-scan:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Run tfsec
        uses: aquasecurity/tfsec-action@v1.0.0
        with:
          soft_fail: true
```

---

### Phase 5: Documentation Updates

#### 5.1 Update README.md

Add these sections to your README:

```markdown
## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- S3 bucket for remote state storage

## Quick Start

1. Clone the repository
   ```bash
   git clone https://github.com/your-org/your-repo.git
   cd your-repo
   ```

2. Configure backend
   ```bash
   cp backend.hcl.example backend.hcl
   # Edit backend.hcl with your S3 bucket details
   ```

3. Configure variables
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

4. Initialize and apply
   ```bash
   terraform init -backend-config=backend.hcl
   terraform plan
   terraform apply
   ```

## Security Notes

- State is stored remotely in S3 with encryption
- No secrets are stored in this repository
- IAM roles follow least-privilege principles
```

---

## Summary Checklist

- [ ] **Phase 1: Security Fixes**
  - [ ] Create `.gitignore`
  - [ ] Delete `terraform.tfstate` from repo
  - [ ] Delete `terraform.tfstate.backup` from repo
  - [ ] Remove state files from git history (if applicable)
  - [ ] Create `terraform.tfvars.example` with sanitized values
  - [ ] Delete original `terraform.tfvars` from repo

- [ ] **Phase 2: Remote State**
  - [ ] Create S3 bucket for state storage
  - [ ] Enable versioning on S3 bucket
  - [ ] Enable encryption on S3 bucket
  - [ ] Block public access on S3 bucket
  - [ ] Update `terraform.tf` with S3 backend
  - [ ] Create `backend.hcl.example`
  - [ ] Migrate existing state to S3

- [ ] **Phase 3: File Organization**
  - [ ] Split `terraform.tf` into `terraform.tf` + `providers.tf`
  - [ ] Optionally create `data.tf` for data sources
  - [ ] Run `terraform fmt` to ensure consistent formatting

- [ ] **Phase 4: CI/CD**
  - [ ] Create `.github/workflows/terraform.yml`
  - [ ] Test workflow on a PR

- [ ] **Phase 5: Documentation**
  - [ ] Update README with setup instructions
  - [ ] Document all variables
  - [ ] Add architecture overview

---

## When to Consider Modules

Your current flat structure is appropriate for this project size. Consider refactoring to modules when:

1. **Multiple environments**: You need dev/staging/prod with similar infrastructure
2. **Code reuse**: You want to share the ECS+ALB pattern across projects
3. **Growth**: The codebase exceeds ~500 lines total
4. **Team boundaries**: Different teams own different components

### Future Module Structure (When Ready)

```
/
├── modules/
│   └── ecs-fargate-service/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── terraform.tf
│   │   └── terraform.tfvars.example
│   ├── staging/
│   └── prod/
└── README.md
```

---

## References

- [Terraform Recommended Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices)
- [S3 Backend Configuration](https://developer.hashicorp.com/terraform/language/backend/s3)
- [Standard Module Structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure)
- [Terraform Style Conventions](https://developer.hashicorp.com/terraform/language/style)
