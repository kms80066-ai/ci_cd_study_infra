variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "web_sg_id" { type = string }
variable "instance_type" { type = string }
variable "volume_size" { type = number }
variable "min_size" { type = number }
variable "desired_size" { type = number }
variable "max_size" { type = number }

variable "key_name" { type = string }
