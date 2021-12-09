locals {
  target_groups = [
    "green",
    "blue",
  ]
}

resource "aws_alb" "main" {
  name            = "${var.env}-alb"
  subnets         = var.public_subnet_ids
  security_groups = [aws_security_group.allow_80.id]
    
}

resource "aws_alb_target_group" "main" {
  count = "${length(local.target_groups)}"

  name = "example-tg-${element(local.target_groups, count.index)}"
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
  load_balancer_arn = "${aws_alb.main.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.main.*.arn[0]}"
  }
}

resource "aws_alb_listener_rule" "main" {
  listener_arn = "${aws_alb_listener.main.arn}"

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.main.*.arn[0]}"
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}