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
  desired_count     = var.desired_capacity
  launch_type       = "EC2"
  
  deployment_controller {
  type = "CODE_DEPLOY"
}
  
  load_balancer {
    target_group_arn    = aws_alb_target_group.main.0.arn
    container_name      = "${var.app_name}-${var.env}"
    container_port      = 80
  }

  depends_on = [
    aws_iam_role.ecs_instance_role,
    aws_alb_listener.main
  ]

}


