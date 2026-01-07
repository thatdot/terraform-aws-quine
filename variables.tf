variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "thatdot-ecs"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "thatdot-ecs-cluster"
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "thatdot-ecs-service"
}

variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "quine"
}

variable "container_image" {
  description = "Docker image to run in the ECS task"
  type        = string
  default     = "thatdot/quine:latest"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 8080
}

variable "container_cpu" {
  description = "CPU units for the container (1024 = 1 vCPU)"
  type        = number
  default     = 2048
}

variable "container_memory" {
  description = "Memory for the container in MB"
  type        = number
  default     = 4096
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "health_check_path" {
  description = "Health check path for the ALB target group"
  type        = string
  default     = "/api/v1/liveness"
}
