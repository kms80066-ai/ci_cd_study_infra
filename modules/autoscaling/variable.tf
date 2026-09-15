variable "name" {
  type = string
}

variable "builder_name" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "builder_subnet_id" {
  type = string
}

variable "builder_instance_type" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "instance_security_group_ids" {
  type = list(string)
}

variable "asg_instance_type" {
  type = string
}

variable "min_size" {
  type = number
}

variable "desired_capacity" {
  type = number
}

variable "max_size" {
  type = number
}

variable "website_bucket" {
  type = string
}

variable "ecr_registry" {
  type = string
}

variable "ecr_repository_names" {
  type = set(string)
}