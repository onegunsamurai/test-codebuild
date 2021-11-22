
locals {
    global_region   = "us-east-1"

    app_name        = "new-app"
    aws_profile     = "default"
    account_id      = "965340621517"
    repository_url  = "https://github.com/onegunsamurai/test-codebuild.git"

# Settings For Dev
    environment_1     = "dev"
    region_1          = "us-east-1"

    desired_capacity_dev    = 1
    max_capacity_dev        = 2
    min_capacity_dev        = 1
    dev_git_secret_arn      = "arn:aws:secretsmanager:us-east-1:965340621517:secret:git_token-n3hMog"


# Settings For Prod  
    environment_2        = "prod"
    region_2             = "us-west-1"

    desired_capacity_prod     = 1
    max_capacity_prod         = 2
    min_capacity_prod         = 1
    prod_git_secret_arn       = "arn:aws:secretsmanager:us-west-1:965340621517:secret:git_token-sKWOkz"

# Number of Availability Zones To Use (Not less than two) -> Req. for ALB
    num_of_zones    = 2
}

inputs = {
    environment_1     = local.environment_1
    environment_2     = local.environment_2
    app_name          = local.app_name
    aws_profile     = local.aws_profile
    account_id      = local.account_id
    repository_url  = local.repository_url
    region_1        = local.region_1
    region_2        = local.region_2
    num_of_zones    = local.num_of_zones
    global_region   = local.global_region

    desired_capacity_dev    = local.desired_capacity_dev
    desired_capacity_prod   = local.desired_capacity_prod
    min_capacity_dev        = local.min_capacity_dev
    min_capacity_prod       = local.min_capacity_prod
    max_capacity_prod       = local.max_capacity_prod
    max_capacity_dev        = local.max_capacity_dev

    dev_git_secret_arn      = local.dev_git_secret_arn
    prod_git_secret_arn     = local.prod_git_secret_arn

}