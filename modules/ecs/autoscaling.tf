resource "aws_autoscaling_group" "main" {
  name = "ecs-${var.env}"

  launch_configuration = aws_launch_configuration.main.id
  
  vpc_zone_identifier  = var.private_subnet_ids

  desired_capacity = var.desired_capacity
  max_size         = var.max_capacity
  min_size         = var.min_capacity

  health_check_grace_period = 20
  health_check_type = "EC2"

  protect_from_scale_in = false

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "ecs"
    propagate_at_launch = true
  }

}


resource "aws_launch_configuration" "main" {
  name = "${var.env}-${var.aws_region}-LaunchConfig"

  iam_instance_profile = aws_iam_instance_profile.ecs_instance_profile.name

  instance_type               = "t2.micro" #Can be improved
  image_id                    = "${data.aws_ami.ecs_ami.image_id}"
  associate_public_ip_address = false
  security_groups             = [aws_security_group.allow_80.id]

  user_data = <<EOF
#!/bin/bash
# The cluster this agent should check into.
echo 'ECS_CLUSTER=${var.env}-ecs-cluster' >> /etc/ecs/ecs.config
# Disable privileged containers.
echo 'ECS_DISABLE_PRIVILEGED=true' >> /etc/ecs/ecs.config
EOF


  lifecycle {
    create_before_destroy = true
  }
}
