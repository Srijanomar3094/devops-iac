provider "aws" {
  region = var.aws_region
}

# VPC Configuration
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  name = "prefect-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a"]
  private_subnets = [cidrsubnet(var.vpc_cidr, 4, 0)]
  public_subnets  = [cidrsubnet(var.vpc_cidr, 4, 1)]

  enable_nat_gateway     = false
  enable_dns_hostnames   = true
  enable_dns_support     = true

  manage_default_network_acl = true
  default_network_acl_ingress = [
    {
      rule_no    = 100
      action     = "allow"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
    }
  ]
  default_network_acl_egress = [
    {
      rule_no    = 100
      action     = "allow"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
    }
  ]

  tags = {
    Name = "prefect-ecs"
    Environment = var.environment
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "prefect_cluster" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    Name = "prefect-ecs"
    Environment = var.environment
  }
}

# Service Discovery
resource "aws_service_discovery_private_dns_namespace" "prefect" {
  name        = "default.prefect.local"
  vpc         = module.vpc.vpc_id
  description = "Private DNS namespace for Prefect service discovery"
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "prefect_task_execution_role" {
  name = "prefect-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "prefect-ecs"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "prefect_task_execution_role_policy" {
  role       = aws_iam_role.prefect_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "prefect_server" {
  name              = "/ecs/prefect-server"
  retention_in_days = 7

  tags = {
    Name = "prefect-ecs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "prefect_worker" {
  name              = "/ecs/prefect-worker"
  retention_in_days = 7

  tags = {
    Name = "prefect-ecs"
    Environment = var.environment
  }
}

# Security Groups
resource "aws_security_group" "prefect_server" {
  name        = "prefect-server-sg"
  description = "Security group for Prefect server"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 4200
    to_port     = 4200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "prefect-ecs"
    Environment = var.environment
  }
}

resource "aws_security_group" "prefect_worker" {
  name        = "prefect-worker-sg"
  description = "Security group for Prefect worker"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "prefect-ecs"
    Environment = var.environment
  }
}

# Prefect Server Task Definition
resource "aws_ecs_task_definition" "prefect_server" {
  family                   = "prefect-server"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = 256
  memory                  = 512
  execution_role_arn      = aws_iam_role.prefect_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "prefect-server"
      image = "prefecthq/prefect:2-latest"
      command = [
        "prefect",
        "server",
        "start",
        "--host",
        "0.0.0.0"
      ]
      environment = [
        {
          name  = "PREFECT_SERVER_HOST"
          value = "0.0.0.0"
        },
        {
          name  = "PREFECT_UI_HOST"
          value = "0.0.0.0"
        },
        {
          name  = "PREFECT_API_HOST"
          value = "0.0.0.0"
        }
      ]
      portMappings = [
        {
          containerPort = 4200
          hostPort      = 4200
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/prefect-server"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "prefect-ecs"
    Environment = var.environment
  }
}

# Prefect Server Service
resource "aws_ecs_service" "prefect_server" {
  name            = "prefect-server"
  cluster         = aws_ecs_cluster.prefect_cluster.id
  task_definition = aws_ecs_task_definition.prefect_server.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
  }

  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.prefect_server.id]
    assign_public_ip = true
  }

  tags = {
    Name        = "prefect-ecs"
    Environment = var.environment
  }
}

# Prefect Worker Task Definition
resource "aws_ecs_task_definition" "prefect_worker" {
  family                   = "prefect-worker"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = 256
  memory                  = 512
  execution_role_arn      = aws_iam_role.prefect_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "prefect-worker"
      image = "prefecthq/prefect:2-latest"
      command = [
        "prefect",
        "worker",
        "start",
        "-p",
        var.work_pool_name
      ]
      environment = [
        {
          name  = "PREFECT_API_URL"
          value = "http://${aws_ecs_service.prefect_server.name}.${aws_service_discovery_private_dns_namespace.prefect.name}:4200/api"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/prefect-worker"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "prefect-ecs"
    Environment = var.environment
  }
}

# Prefect Worker Service
resource "aws_ecs_service" "prefect_worker" {
  name            = var.worker_name
  cluster         = aws_ecs_cluster.prefect_cluster.id
  task_definition = aws_ecs_task_definition.prefect_worker.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
  }

  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.prefect_worker.id]
    assign_public_ip = true
  }

  tags = {
    Name        = "prefect-ecs"
    Environment = var.environment
  }
}
