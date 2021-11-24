variable "aws_region" {
  description = "aws region"
}

variable "aws_profile" {
  description = "AWS Profile"
}

variable "env" {
  description = "environment"
}

variable "vpc_id" {
  description = "Passed VPC id."
}

variable "public_subnet_ids" {
  type = set(string)
  description = "Public Subnet ID list"
}

variable "private_subnet_ids" {
  type = set(string)
  description = "Private Subnet ID list"
}


variable "app_cpu" {
  description = "CPU Credits for a node"
  default = 256
}

variable "app_memory" {
  description = "Memory for a node"
  default = 512
}

variable "app_name" {
  description = "Application Name"
}

variable "node_count" {
  description = "Desired Amount of Nodes/Instances"
  default = 2
}

variable "desired_capacity" {
  
}

variable "max_capacity" {
  
}

variable "min_capacity" {
  
}

variable "image_tag" {
  
}