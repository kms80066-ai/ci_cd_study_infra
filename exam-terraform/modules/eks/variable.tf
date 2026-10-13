variable "name_prefix" { type = string }
variable "cluster_name" { type = string }
variable "cluster_subnet_ids" { type = list(string) }
variable "node_instance_type" { type = string }
variable "min_size" { type = number }
variable "desired_size" { type = number }
variable "max_size" { type = number }

