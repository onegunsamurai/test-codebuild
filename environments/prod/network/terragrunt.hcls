

locals {
    common_vars         = read_terragrunt_config(find_in_parent_folders())
    aws_region          = local.common_vars.inputs.region_2
    env                 = local.common_vars.inputs.environment_2
}

terraform {
    source = "../../../modules//network"
}

include {
    path = find_in_parent_folders()
}


# TOO BAD ASS SOLUTION FOR IT TO BELIEVE IT WORKS
inputs = merge(
    local.common_vars.inputs,
    {
        aws_region = local.aws_region
        env        = local.env
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
