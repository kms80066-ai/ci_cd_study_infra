variable "name_prefix" { type = string }
variable "vpc_cidr" { type = string }
variable "cluster_name" { type = string }
variable "subnet_map" {
  type = map(object({
    kind = string
    az   = string
    cidr = string
  }))
}

