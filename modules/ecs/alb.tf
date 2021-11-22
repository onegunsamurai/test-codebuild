resource "aws_alb" "main" {
  name            = "${var.env}-alb"
  subnets         = var.public_subnet_ids
  security_groups = [aws_security_group.allow_80.id]
    
}

resource "aws_alb_target_group" "main" {
  name        = "${var.env}-tg-default"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
  health_check {
    healthy_threshold   = "3"
    interval            = "10"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }
  lifecycle {
      create_before_destroy = true
    }
}

resource "aws_alb_listener" "main" {
  load_balancer_arn = aws_alb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.main.id
    type             = "forward"
  }
  depends_on = [
    aws_security_group.allow_80
  ]
}