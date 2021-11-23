data "aws_secretsmanager_secret" "git" {
  arn = var.git_secret_arn
}

data "aws_secretsmanager_secret_version" "git" {
  secret_id = data.aws_secretsmanager_secret.git.id
}

locals {
  github_oauth_token = jsondecode(data.aws_secretsmanager_secret_version.git.secret_string)["git_token"]
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

module "build" {
    source = "cloudposse/codebuild/aws"
        # Cloud Posse recommends pinning every module to a specific version
    # version     = "x.x.x"
    namespace           = "eg"
    stage               = "${var.env}"
    name                = "${var.app_name}"


    depends_on = [null_resource.import_source_credentials, aws_cloudwatch_log_group.codebuild]
    source_type                     = "GITHUB"
    source_location                 = var.repository_url
    source_credential_auth_type     = "PERSONAL_ACCESS_TOKEN"
    source_credential_server_type   = "GITHUB"
    source_credential_token         = local.github_oauth_token
    git_clone_depth                 = 1
    artifact_type                   = "NO_ARTIFACTS"
    buildspec                       = "app/buildspec.yaml"

    delimiter = "-"

        extra_permissions = [
                "codebuild:*",
                "codecommit:*",
                "cloudwatch:*",
                "ec2:*",
                "ecr:*",
                "iam:*",
                "elasticfilesystem:*",
                "events:*",
                "logs:*",
                "s3:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "ecs:*"
    ]


    # https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html
    build_image         = "aws/codebuild/standard:4.0"
    build_compute_type  = "BUILD_GENERAL1_SMALL"
    build_timeout       = 60

    # These attributes are optional, used as ENV variables when building Docker images and pushing them to ECR
    # For more info:
    # http://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html
    # https://www.terraform.io/docs/providers/aws/r/codebuild_project.html

    privileged_mode     = true              # Used when we need to run a docker Container inside codebuild docker image. 
    aws_region          = var.aws_region
    aws_account_id      = var.account_id
    image_repo_name     = local.image_repo_name
    image_tag           = "latest"

    vpc_config = {
        vpc_id = var.vpc_id
        subnets = var.private_subnet_ids
        security_group_ids = [aws_security_group.codebuild_security.id]
    }

    logs_config = {
        cloudwatch_logs = {
            group_name = aws_cloudwatch_log_group.codebuild.name
            stream_name = aws_cloudwatch_log_stream.codebuild.name
        }
    }

    environment_variables = [
      {
        "name": "ECR_REGION"
        "type": "PLAINTEXT"
        "value": "${var.aws_region}"
      },
      {
        "name": "ECR_REPO_NAME"
        "type": "PLAINTEXT"
        "value": "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.image_repo_name}"
      },
      {
        "name": "ACCOUNT_NUMBER"
        "type": "PLAINTEXT"
        "value": "${var.account_id}"
      },
      {
        "name": "CONTAINER_NAME"
        "type": "PLAINTEXT"
        "value": "${var.app_name}-${var.env}-container"
      },
      {
        "name": "ENV"
        "type": "PLAINTEXT"
        "value": "${var.env}"
      }
    ]

    # Optional extra environment variables

}

resource "aws_codebuild_webhook" "example" {
  project_name = module.build.project_name
  build_type   = "BUILD"
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "main"
    }
  }
}

resource "aws_cloudwatch_log_group" "codebuild" {
  name = "${var.env}-codebuild"
}

resource "aws_cloudwatch_log_stream" "codebuild" {
  name           = "${var.env}-MainStream"
  log_group_name = aws_cloudwatch_log_group.codebuild.name
}