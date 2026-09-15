variable "bucket_prefix" { type = string }
variable "tag_header" { type = string }
variable "private_subnets" { type = map(string) }
variable "efs_sg_id" { type = string }
