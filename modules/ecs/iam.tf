data "aws_iam_policy_document" "ecs_instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name               = "${var.env}-ecs-instance-role-${var.aws_region}"
  assume_role_policy = data.aws_iam_policy_document.ecs_instance_assume_role_policy.json
}

resource "aws_iam_policy_attachment" "ecs_to_ec2" {
  name       = "${var.env}-policy-connect"
  roles       = [aws_iam_role.ecs_instance_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.env}-ecsInstanceRole-${var.app_name}"
  path = "/"
  role = aws_iam_role.ecs_instance_role.name
}


# resource "aws_iam_role" "ecs_task_execution" {
#     name        = "${var.env}EcsTaskExecutionRole"
#     assume_role_policy  = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "",
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "ecs-tasks.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
#     EOF
# }

# resource "aws_iam_role_policy" "ecs_task_execution" {
#     name_prefix         = "${var.env}EcsTaskExecutionRolePolicy"
#     role                = aws_iam_role.ecs_task_execution.id
#     policy              = data.template_file.ecs_full_access_policy.rendered
# }


# data "template_file" "ecs_full_access_policy" {
#   template = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Effect": "Allow",
#         "Action": [
#           "ecs:DeregisterContainerInstance",
#           "ecs:DiscoverPollEndpoint",
#           "ecs:Poll",
#           "ecs:RegisterContainerInstance",
#           "ecs:StartTelemetrySession",
#           "ecs:Submit*",
#           "ecr:GetAuthorizationToken",
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:BatchGetImage",
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents",
#           "logs:DescribeLogStreams"
#         ],
#         "Resource": "*"
#       },
#       {
#         "Effect": "Allow",
#         "Action": [
#           "ec2:Describe",
#           "ec2:DescribeInstances"
#         ],
#         "Resource": [
#           "*"
#         ]
#       },
#       {
#         "Effect": "Allow",
#         "Action": [
#           "ssm:GetParameters",
#           "ssm:GetParametersByPath"
#         ],
#         "Resource": [
#           "arn:aws:ssm:*:*:parameter/*"
#         ]
#       },
#       {
#         "Effect": "Allow",
#         "Action": [
#           "secretsmanager:GetSecretValue"
#         ],
#         "Resource": [
#           "arn:aws:secretsmanager:*:*:secret:*"
#         ]
#       },
#       {
#         "Sid": "",
#         "Effect": "Allow",
#         "Action": [
#           "kms:ListKeys",
#           "kms:ListAliases",
#           "kms:Describe*",
#           "kms:Decrypt"
#         ],
#         "Resource": "*"
#       }
#     ]
# }
# EOF
# }


# resource "aws_iam_role" "ecs_task_role" {
#     name        = "${var.env}ecs_task_role"
#     assume_role_policy  = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Sid": "",
#         "Effect": "Allow",
#         "Principal": {
#           "Service": "ecs-tasks.amazonaws.com"
#         },
#         "Action": "sts:AssumeRole"
#       }
#     ]
# }
# EOF
# }




# resource "aws_iam_role_policy" "ecs_task_role" {
#   name    = "${var.env}ecs_task_role_policy"
#   role    = aws_iam_role.ecs_task_role.id
#   policy  = <<EOF
# {
#       "Version": "2012-10-17",
#       "Statement": [
#           {
#               "Effect": "Allow",
#               "Action": [
#                   "s3:Get*",
#                   "s3:List*",
#                   "s3:Put*",
#                   "s3:Delete*"
#               ],
#               "Resource": "*"
#           }
#       ]
# }
# EOF
# }




# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": ["s3:ListBucket"],
#       "Resource":["arn:aws:s3:::${var.bucket_name}"]
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "s3:GetObject",
#         "s3:PutObject",
#         "s3:DeleteObject"
#       ],
#       "Resource": [
#         "arn:aws:s3:::${var.bucket_name}/*"
#       ]
#     }
#   ]
# }