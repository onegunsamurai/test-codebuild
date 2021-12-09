locals {
    common_vars         = read_terragrunt_config(find_in_parent_folders())
    aws_region          = local.common_vars.inputs.region_1
    env                 = local.common_vars.inputs.environment_1
    git_secret_arn      = local.common_vars.inputs.dev_git_secret_arn
}


terraform {
    source = "../../../modules//codebuild"
}

include {
    path = find_in_parent_folders()
}


dependencies {
    paths = ["../network","../ecs"]
}


dependency "network" {
    config_path = "../network"
    mock_outputs = {
        vpc_id              = "vpc-000000000000"
        public_subnet_ids   = ["subnet-00000000000", "subnet-111111111111"]
        private_subnet_ids   = ["subnet-22222222222", "subnet-444444444444"]
    }
}

dependency "ecs" {
    config_path = "../ecs"
}

inputs = merge(
    local.common_vars.inputs,
    {
    vpc_id                  = dependency.network.outputs.vpc_id
    public_subnet_ids       = dependency.network.outputs.public_subnet_ids
    private_subnet_ids      = dependency.network.outputs.private_subnet_ids
    aws_region              = local.aws_region
    env                     = local.env
    git_secret_arn          = local.git_secret_arn
    aws_ecs_task_definition = dependency.ecs.outputs.aws_ecs_task_definition
    target_group_name_1     = dependency.ecs.outputs.target_group_name_1
    target_group_name_2     = dependency.ecs.outputs.target_group_name_2
    listener_arns           = dependency.ecs.outputs.listener_arns
    }
)

remote_state {
    backend = "s3"
    generate = {
        path = "backend.tf"
        if_exists = "overwrite_terragrunt"
    }
    config = {
        bucket     = "${local.common_vars.inputs.app_name}-${local.env}-${local.aws_region}-bucket"
        key        = "${path_relative_to_include()}/terraform.tfstate"
        encrypt    = true
        profile    = local.common_vars.inputs.aws_profile
        region     = local.aws_region
    }
}
