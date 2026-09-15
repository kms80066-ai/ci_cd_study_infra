resource "aws_subnet" "this" {
  for_each = local.subnet_map

  vpc_id                                      = aws_vpc.this.id
  cidr_block                                  = each.value.cidr
  availability_zone                           = each.value.az
  map_public_ip_on_launch                     = each.value.type == "public"
  enable_resource_name_dns_a_record_on_launch = true

  tags = merge(
    {
      Name = "${local.tag_header}${each.key}-subnet"
      Type = each.value.type
    },
    each.value.type != "private" ? {
      "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    } : {},
    each.value.type == "public" ? {
      "kubernetes.io/role/elb" = "1"
    } : {},
    each.value.type == "cluster" ? {
      "kubernetes.io/role/internal-elb" = "1"
    } : {}
  )
}
