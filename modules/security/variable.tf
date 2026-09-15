variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "tag_header" { type = string }
variable "non_public_cidrs" { type = list(string) }
