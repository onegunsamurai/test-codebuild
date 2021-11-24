data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-2018.03.y-amazon-ecs-optimized"]
  }
}


resource "aws_ecs_cluster" "main" {
  name              = "${var.env}-ecs-cluster"
  # Internal Module Dependency Hook to create ECR prior ECS
  capacity_providers = [aws_ecs_capacity_provider.main.name]
  lifecycle {
    create_before_destroy = true
  }
  depends_on        = [
      aws_autoscaling_group.main
  ]
}

resource "aws_ecs_task_definition" "nginx" {
  family                    = "web_servers"
  network_mode              = "bridge"
  requires_compatibilities  = ["EC2"]
  cpu                       = var.app_cpu
  memory                    = var.app_memory
  #--------------WEAK BLOCK HERE------------------------------------
  container_definitions     = jsonencode([
      {
          name      = "${var.app_name}-${var.env}"
          image     = "${aws_ecr_repository.default.repository_url}:${var.image_tag}"
          cpu       = "${var.app_cpu}"
          memory    = "${var.app_memory}"
          essential = true
          portMappings = [
              {
                  containerPort = 80
                  hostPort      = 80
              }
          ]
      }
  ])
  #-----------------------------------------------------------------
}


resource "aws_ecs_service" "main" {
  name              = "${var.env}-ecs-service"
  cluster           = aws_ecs_cluster.main.id
  task_definition   = aws_ecs_task_definition.nginx.arn

  load_balancer {
    target_group_arn    = aws_alb_target_group.main.arn
    container_name      = "${var.app_name}-${var.env}"
    container_port      = 80
  }

  depends_on = [
    aws_iam_role.ecs_instance_role,
    aws_alb_listener.main
  ]

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight = 200
    base = var.desired_capacity
  }
}


resource "aws_ecs_capacity_provider" "main" {
  name = "${var.env}-cap-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.main.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}