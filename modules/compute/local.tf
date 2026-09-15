locals {
  name               = var.name
  subnet_id          = var.subnet_id
  security_group_ids = var.security_group_ids
  key_name           = var.key_name
  efs_dns_name       = var.efs_dns_name

  ami_id        = data.aws_ami.ubuntu.id
  instance_type = "t3.nano"

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    efs_dns_name = local.efs_dns_name
  })
}
