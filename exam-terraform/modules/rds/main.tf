resource "aws_db_subnet_group" "mysql" {
  name       = "${local.name_prefix}-mysql-subnets"
  subnet_ids = local.private_subnet_ids
  tags       = { Name = "${local.name_prefix}-mysql-subnets" }
}

resource "aws_db_instance" "mysql" {
  identifier                 = "${local.name_prefix}-mysql"
  engine                     = "mysql"
  instance_class             = local.instance_class
  allocated_storage          = 20
  storage_type               = "gp3"
  storage_encrypted          = true
  db_name                    = local.db_name
  username                   = local.db_username
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.mysql.name
  vpc_security_group_ids = [local.db_sg_id]
  publicly_accessible   = false
  multi_az              = false

  # 실습용: destroy 가능, 백업 보존 안 함
  backup_retention_period = 0
  deletion_protection     = false
  skip_final_snapshot     = true
  auto_minor_version_upgrade = true

  tags = { Name = "${local.name_prefix}-mysql" }
}

