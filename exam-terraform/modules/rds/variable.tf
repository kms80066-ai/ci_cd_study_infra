variable "name_prefix" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "db_sg_id" { type = string }
variable "instance_class" { type = string }
variable "db_name" { type = string }
variable "db_username" { type = string }

variable "multi_az" { type = bool }
