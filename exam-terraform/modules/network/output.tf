output "vpc_id" { value = aws_vpc.this.id }
output "subnet_ids" {
  value = { for k, v in aws_subnet.this : k => v.id }
}
output "public_subnet_ids" {
  value = [for k in sort(keys(local.public_subnets)) : aws_subnet.this[k].id]
}
output "private_subnet_ids" {
  value = [for k in sort(keys(local.private_subnets)) : aws_subnet.this[k].id]
}
output "cluster_subnet_ids" {
  value = [for k in sort(keys(local.cluster_subnets)) : aws_subnet.this[k].id]
}

