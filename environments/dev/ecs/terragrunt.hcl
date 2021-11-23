locals {
    common_vars         = read_terragrunt_config(find_in_parent_folders())
    aws_region          = local.common_vars.inputs.region_1
    env                 = local.common_vars.inputs.environment_1
    desired_capacity    = local.common_vars.inputs.desired_capacity_dev
    min_capacity        = local.common_vars.inputs.min_capacity_dev
    max_capacity        = local.common_vars.inputs.max_capacity_dev
}


terraform {
    source = "../../../modules//ecs"
}

include {
    path = find_in_parent_folders()
}


dependencies {
    paths = ["../network"]
}

dependency "network" {
    config_path = "../network"
    mock_outputs = {
        vpc_id              = "vpc-000000000000"
        public_subnet_ids   = ["subnet-00000000000", "subnet-111111111111"]
        private_subnet_ids   = ["subnet-22222222222", "subnet-444444444444"]
    }
}


inputs = merge(
    local.common_vars.inputs,
    {
    vpc_id                  = dependency.network.outputs.vpc_id
    public_subnet_ids       = dependency.network.outputs.public_subnet_ids
    private_subnet_ids      = dependency.network.outputs.private_subnet_ids
    aws_region              = local.aws_region
    env                     = local.env
    desired_capacity        = local.desired_capacity
    min_capacity            = local.min_capacity
    max_capacity            = local.max_capacity
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
