locals {
  # ========================================================
  # Input
  # ========================================================

  name         = var.name
  builder_name = var.builder_name

  region = var.region
  vpc_id = var.vpc_id

  builder_subnet_id     = var.builder_subnet_id
  builder_instance_type = var.builder_instance_type

  public_subnet_ids  = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids

  alb_security_group_id       = var.alb_security_group_id
  instance_security_group_ids = var.instance_security_group_ids

  asg_instance_type = var.asg_instance_type

  min_size         = var.min_size
  desired_capacity = var.desired_capacity
  max_size         = var.max_size

  website_bucket = var.website_bucket

  ecr_registry         = var.ecr_registry
  ecr_repository_names = var.ecr_repository_names


  # ========================================================
  # Amazon Linux 2023
  # ========================================================

  base_ami_id = data.aws_ssm_parameter.al2023_latest.value


  # ========================================================
  # IAM
  # ========================================================

  ec2_assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })


  builder_role_name        = "${local.builder_name}-role"
  builder_instance_profile = "${local.builder_name}-profile"

  builder_policy_arns = toset([
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])


  asg_role_name        = "${local.name}-role"
  asg_instance_profile = "${local.name}-profile"

  asg_policy_arns = toset([
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])


  # ========================================================
  # 이름
  # ========================================================

  alb_name          = "${local.name}-alb"
  target_group_name = "${local.name}-tg"


  # ========================================================
  # User Data
  # ========================================================

  builder_user_data = templatefile(
    "${path.module}/user_data_ami.sh.tftpl",
    {}
  )

  asg_user_data = templatefile(
    "${path.module}/user_data_asg.sh.tftpl",
    {
      region         = local.region
      website_bucket = local.website_bucket
      ecr_registry   = local.ecr_registry
    }
  )


  # ========================================================
  # AMI 제작 완료 확인용
  # ========================================================

  ami_validation_command = <<-EOT
    set -e

    cloud-init status --wait

    test -f /var/tmp/docker-ami-ready

    systemctl is-active docker

    docker --version

    docker compose version
  EOT
}
