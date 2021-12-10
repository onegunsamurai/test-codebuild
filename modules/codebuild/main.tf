data "aws_secretsmanager_secret" "git" {
  arn = var.git_secret_arn
}

data "aws_secretsmanager_secret_version" "git" {
  secret_id = data.aws_secretsmanager_secret.git.id
}


locals {
  github_oauth_token = jsondecode(data.aws_secretsmanager_secret_version.git.secret_string)["git_token_dec"]
  image_repo_name     = "${var.env}-ecr-master"
}

resource "null_resource" "import_source_credentials" {

  
  triggers = {
    github_oauth_token = local.github_oauth_token
  }

  provisioner "local-exec" {
    command = <<EOF
      aws --region ${var.aws_region} codebuild import-source-credentials \
                                                             --token ${local.github_oauth_token} \
                                                             --server-type GITHUB \
                                                             --auth-type PERSONAL_ACCESS_TOKEN
EOF
  }
}


resource "aws_cloudwatch_log_group" "codebuild" {
  name = "${var.env}-codebuild"
}

resource "aws_cloudwatch_log_stream" "codebuild" {
  name           = "${var.env}-MainStream"
  log_group_name = aws_cloudwatch_log_group.codebuild.name
}

#===================================================
#               CODE PIPELINE PART
#===================================================

resource "aws_s3_bucket" "this" {
  bucket = "${var.env}-something-cool-123asd"
}


data "aws_iam_policy_document" "assume_by_pipeline" {
  statement {
    sid     = "AllowAssumeByPipeline"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "pipeline" {

  statement {
    sid    = "AllowS3"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.this.arn}",
      "${aws_s3_bucket.this.arn}/*",
    ]
  }

  statement {
    sid    = "AllowCodeBuild"
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["${aws_codebuild_project.this.arn}"]
  }


  statement {
    sid    = "AllowCodeDeploy"
    effect = "Allow"

    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision",
    ]

    resources = ["*"]
  }

  statement {
      sid    = "AllowECS"
      effect = "Allow"

      actions = ["ecs:*"]

      resources = ["*"]
    }

  statement {
      sid    = "AllowPassRole"
      effect = "Allow"

      resources = ["*"]

      actions = ["iam:PassRole"]

      condition {
        test     = "StringLike"
        values   = ["ecs-tasks.amazonaws.com"]
        variable = "iam:PassedToService"
      }
    }
  
  

}

resource "aws_iam_role" "pipeline" {
  name               = "pipeline-example-role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_by_pipeline.json}"
}

resource "aws_iam_role_policy" "pipeline" {
  role   = "${aws_iam_role.pipeline.name}"
  policy = "${data.aws_iam_policy_document.pipeline.json}"
}



resource "aws_codepipeline" "this" {
  name      = "${var.aws_region}-pipeline"
  role_arn  = "${aws_iam_role.pipeline.arn}"

 artifact_store {
    location = "${aws_s3_bucket.this.bucket}"
    type     = "S3"
  }
  stage {

    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        OAuthToken = "${local.github_oauth_token}"
        Owner      = "onegunsamurai"
        Repo       = "test-codebuild"
        Branch     = "main"
      }
    }
  }

  stage {

    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source"]
      output_artifacts = ["build"]

      configuration = {
        ProjectName = "${aws_codebuild_project.this.name}"
      }
    }
  }

    stage {

      name = "Deploy"

      action {
        name            = "Deploy"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "CodeDeployToECS"
        version         = "1"
        input_artifacts = ["build"]

        configuration = {
          ApplicationName                = "${aws_codedeploy_app.this.name}"
          DeploymentGroupName            = "${aws_codedeploy_deployment_group.this.deployment_group_name}"
          TaskDefinitionTemplateArtifact = "build"
          AppSpecTemplateArtifact        = "build"
        }
      }
    }
}




data "aws_iam_policy_document" "assume_by_codebuild" {
  statement {
    sid     = "AllowAssumeByCodebuild"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "codebuild-example-role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_by_codebuild.json}"
}

data "aws_iam_policy_document" "codebuild" {
  statement {
    sid    = "AllowS3"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.this.arn}",
      "${aws_s3_bucket.this.arn}/*",
    ]
  }

  statement {
    sid    = "AllowECRAuth"
    effect = "Allow"

    actions = ["ecr:GetAuthorizationToken"]

    resources = ["*"]
  }

  statement {
    sid    = "AllowECRUpload"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecs:RunTask",
      "iam:PassRole",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ssm:GetParameters",
      "secretsmanager:GetSecretValue"
    ]

    resources = ["*"]
  }

  statement {
    sid       = "AllowECSDescribeTaskDefinition"
    effect    = "Allow"
    actions   = ["ecs:DescribeTaskDefinition"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowLogging"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild" {
  role   = "${aws_iam_role.codebuild.name}"
  policy = "${data.aws_iam_policy_document.codebuild.json}"
}


resource "aws_codebuild_project" "this" {
  name         = "${var.env}-codebuild"
  service_role = "${aws_iam_role.codebuild.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/docker:18.09.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name = "ECR_REPO_NAME"
      type = "PLAINTEXT"
      value = "${local.image_repo_name}"
    }
    environment_variable {
      name = "ECR_REGION"
      type = "PLAINTEXT"
      value = "${var.aws_region}"
    }
    environment_variable {
      name = "ACCOUNT_NUMBER"
      type = "PLAINTEXT"
      value = "${var.account_id}"
    }
    environment_variable {
      name = "CONTAINER_NAME"
      type = "PLAINTEXT"
      value = "${var.app_name}-${var.env}-container"
    }
    environment_variable {
      name = "ENV"
      type = "PLAINTEXT"
      value = "${var.env}"
    }
    environment_variable {
      name = "CLUSTER_NAME"
      type = "PLAINTEXT"
      value = "${var.env}-ecs-cluster"
    }
    environment_variable {
      name = "SERVICE_NAME"
      type = "PLAINTEXT"
      value = "${var.env}-ecs-service"
    }
    environment_variable {
      name  = "TASK_DEFINITION"
      value = "arn:aws:ecs:${var.aws_region}:${var.account_id}:task-definition/${var.aws_ecs_task_definition}"
    }
    environment_variable {
      name  = "SUBNET_1"
      value = "${var.private_subnet_ids[0]}"
    }
    environment_variable {
      name  = "SUBNET_2"
      value = "${var.private_subnet_ids[1]}"
    }
    environment_variable {
      name  = "SECURITY_GROUP"
      value = "${aws_security_group.codebuild_security.id}"
    }

  }
  source {
    type = "CODEPIPELINE"
  }

}


#=============================================================
#
#               CODE_DEPLOY
#
#=============================================================


data "aws_iam_policy_document" "assume_by_codedeploy" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codedeploy" {
  name               = "codedeploy"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}


resource "aws_iam_role_policy_attachment" "AWSCodeDeployRoleForECS" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
  role       = aws_iam_role.codedeploy.name
}



resource "aws_codedeploy_app" "this" {
  compute_platform = "ECS"
  name             = "example"
}

resource "aws_codedeploy_deployment_group" "this" {
  app_name               = "${aws_codedeploy_app.this.name}" 
  deployment_group_name  = "example-deploy-group"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.codedeploy.arn

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
    }
  }

  ecs_service {
    cluster_name = "${var.env}-ecs-cluster"
    service_name = "${var.env}-ecs-service"
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.listener_arns]
      }

      target_group {
        name = "${var.target_group_name_1}"
      }

      target_group {
        name = "${var.target_group_name_2}"
      }
    }
  }
  depends_on = [
      aws_iam_role.codedeploy
  ]
}








































# module "build" {
#     source = "cloudposse/codebuild/aws"
#         # Cloud Posse recommends pinning every module to a specific version
#     # version     = "x.x.x"
#     namespace           = "eg"
#     stage               = "${var.env}"
#     name                = "${var.app_name}"


#     depends_on = [null_resource.import_source_credentials, aws_cloudwatch_log_group.codebuild]
#     source_type                     = "GITHUB"
#     source_location                 = var.repository_url
#     source_credential_auth_type     = "PERSONAL_ACCESS_TOKEN"
#     source_credential_server_type   = "GITHUB"
#     source_credential_token         = local.github_oauth_token
#     git_clone_depth                 = 1
#     artifact_type                   = "NO_ARTIFACTS"
#     buildspec                       = "app/buildspec.yaml"

#     delimiter = "-"

#     extra_permissions = [
#                 "codebuild:*",
#                 "codecommit:*",
#                 "cloudwatch:*",
#                 "ec2:*",
#                 "ecr:*",
#                 "iam:*",
#                 "elasticfilesystem:*",
#                 "events:*",
#                 "logs:*",
#                 "s3:*",
#                 "elasticloadbalancing:*",
#                 "autoscaling:*",
#                 "ecs:*"

#     ]


#     # https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html
#     build_image         = "aws/codebuild/standard:4.0"
#     build_compute_type  = "BUILD_GENERAL1_SMALL"
#     build_timeout       = 60

#     # These attributes are optional, used as ENV variables when building Docker images and pushing them to ECR
#     # For more info:
#     # http://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html
#     # https://www.terraform.io/docs/providers/aws/r/codebuild_project.html

#     privileged_mode     = true              # Used when we need to run a docker Container inside codebuild docker image. 
#     aws_region          = var.aws_region
#     aws_account_id      = var.account_id
#     image_repo_name     = local.image_repo_name
#     image_tag           = var.image_tag

#     vpc_config = {
#         vpc_id = var.vpc_id
#         subnets = var.private_subnet_ids
#         security_group_ids = [aws_security_group.codebuild_security.id]
#     }

#     logs_config = {
#         cloudwatch_logs = {
#             group_name = aws_cloudwatch_log_group.codebuild.name
#             stream_name = aws_cloudwatch_log_stream.codebuild.name
#         }
#     }

#     environment_variables = [
#       {
#         "name": "ECR_REGION"
#         "type": "PLAINTEXT"
#         "value": "${var.aws_region}"
#       },
#       {
#         "name": "ECR_REPO_NAME"
#         "type": "PLAINTEXT"
#         "value": "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.image_repo_name}"
#       },
#       {
#         "name": "ACCOUNT_NUMBER"
#         "type": "PLAINTEXT"
#         "value": "${var.account_id}"
#       },
#       {
#         "name": "CONTAINER_NAME"
#         "type": "PLAINTEXT"
#         "value": "${var.app_name}-${var.env}-container"
#       },
#       {
#         "name": "ENV"
#         "type": "PLAINTEXT"
#         "value": "${var.env}"
#       },
#       {
#         "name": "CLUSTER_NAME"
#         "type": "PLAINTEXT"
#         "value": "${var.env}-ecs-cluster"
#       },
#       {
#         "name": "SERVICE_NAME"
#         "type": "PLAINTEXT"
#         "value": "${var.env}-ecs-service"
#       }
#     ]

#     # Optional extra environment variables

# }

# resource "aws_codebuild_webhook" "example" {
#   project_name = module.build.project_name
#   build_type   = "BUILD"
#   filter_group {
#     filter {
#       type    = "EVENT"
#       pattern = "PUSH"
#     }

#     filter {
#       type    = "HEAD_REF"
#       pattern = "main"
#     }
#   }
# }