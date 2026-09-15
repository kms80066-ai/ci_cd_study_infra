variable "cluster_name" {
  type = string
}

variable "tag_header" {
  type = string
}

variable "cluster_subnet_ids" {
  type = list(string)
}

variable "node_subnet_ids" {
  type = list(string)
}

variable "cluster_security_group_id" {
  type = string
}

variable "node_security_group_id" {
  type = string
}

variable "node_instance_type" {
  type = string
}

variable "min_size" {
  type = number
}

variable "desired_size" {
  type = number
}

variable "max_size" {
  type = number
}