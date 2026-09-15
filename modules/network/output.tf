output "vpc_id" {
  value = aws_vpc.this.id
}

output "subnet_ids" {
  value = { for key, subnet in aws_subnet.this : key => subnet.id }
}

output "public_subnet_ids" {
  value = [for key, subnet in aws_subnet.this : subnet.id if contains(keys(local.public_subnets), key)]
}

output "private_subnet_ids" {
  value = [for key, subnet in aws_subnet.this : subnet.id if contains(keys(local.private_subnets), key)]
}

output "cluster_subnet_ids" {
  value = [for key, subnet in aws_subnet.this : subnet.id if contains(keys(local.cluster_subnets), key)]
}

output "private_subnets_by_az" {
  value = {
    for key, subnet in aws_subnet.this : local.subnet_map[key].az => subnet.id
    if contains(keys(local.private_subnets), key)
  }
}

output "non_public_route_table_ids" {
  value = concat(
    [for route_table in aws_route_table.private : route_table.id],
    [aws_route_table.cluster.id]
  )
}

output "nat_public_ip" {
  value = aws_eip.nat.public_ip
}
