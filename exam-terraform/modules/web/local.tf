locals {
  name_prefix        = var.name_prefix
  vpc_id             = var.vpc_id
  public_subnet_ids  = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids
  alb_sg_id          = var.alb_sg_id
  web_sg_id          = var.web_sg_id
  key_name           = var.key_name
  instance_type      = var.instance_type
  volume_size        = var.volume_size
  min_size           = var.min_size
  desired_size       = var.desired_size
  max_size           = var.max_size
  asg_name           = "${local.name_prefix}-nginx-asg"
  alb_name           = "${local.name_prefix}-nginx-alb"
  tg_name            = "${local.name_prefix}-nginx-tg"
}

