locals {
  region                     = var.region
  vpc_id                     = var.vpc_id
  tag_header                 = var.tag_header
  private_subnet_ids         = var.private_subnet_ids
  non_public_route_table_ids = var.non_public_route_table_ids
  endpoint_sg_id             = var.endpoint_sg_id

  s3_service_name = data.aws_vpc_endpoint_service.s3.service_name
  ecr_services    = toset(["ecr.api", "ecr.dkr"])
}
