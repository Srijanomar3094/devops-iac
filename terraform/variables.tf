variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "work_pool_name" {
  description = "Name of the Prefect work pool"
  type        = string
  default     = "ecs-work-pool"
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "prefect-cluster"
}

variable "worker_name" {
  description = "Name of the Prefect worker service"
  type        = string
  default     = "prefect-worker"
}
