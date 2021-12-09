output "aws_ecs_task_definition" {
    value = aws_ecs_task_definition.nginx.family
}

output "target_group_name_1" {
    value = aws_alb_target_group.main.*.name[0]
}

output "target_group_name_2" {
    value = aws_alb_target_group.main.*.name[1]
}

output "listener_arns" {
    value = aws_alb_listener.main.arn
}