variable "region" { type = string }
variable "vpc_id" { type = string }
variable "tag_header" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "non_public_route_table_ids" { type = list(string) }
variable "endpoint_sg_id" { type = string }
