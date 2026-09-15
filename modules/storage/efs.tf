resource "aws_efs_file_system" "this" {
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name = "${local.tag_header}efs"
  }
}

# EFS는 하나이고, 접속 창구인 Mount Target만 AZ마다 하나씩 만듭니다.
resource "aws_efs_mount_target" "this" {
  for_each = local.private_subnets

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [local.efs_sg_id]
}
