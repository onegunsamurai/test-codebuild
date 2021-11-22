variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "aws_public_subnets" {
  default = [
    "10.0.10.0/24",
    "10.0.11.0/24"
  ]
}

variable "aws_private_subnets" {
  default = [
    "10.0.20.0/24",
    "10.0.21.0/24"
  ]
}

variable "aws_database_subnets" {
  default = [
    "10.0.30.0/24",
    "10.0.31.0/24"
  ]
}

variable "aws_region" {
  description = "aws region"
}

variable "aws_profile" {
  description = "AWS Profile"
}
variable "env" {
  description = "environment"
}

variable "num_of_zones" {
  
}