output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.prefect_cluster.arn
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "prefect_worker_service_name" {
  description = "Name of the Prefect worker service"
  value       = aws_ecs_service.prefect_worker.name
}

output "prefect_worker_task_definition_arn" {
  description = "ARN of the Prefect worker task definition"
  value       = aws_ecs_task_definition.prefect_worker.arn
}
