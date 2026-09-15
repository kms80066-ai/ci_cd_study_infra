variable "vpc_cidr" { type = string }
variable "tag_header" { type = string }
variable "azs" { type = list(string) }
variable "subnet_map" {
  type = map(object({ type = string, az = string, cidr = string }))
}
variable "cluster_name" { type = string }
