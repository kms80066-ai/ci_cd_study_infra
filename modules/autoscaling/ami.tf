# ========================================================
# AMI Builder 전용 Security Group
#
# SSH / HTTP Inbound 필요 없음
# Private Subnet에서 NAT를 통해 외부 다운로드만 수행
# ========================================================

resource "aws_security_group" "ami_builder" {
  name        = "${local.builder_name}-sg"
  description = "Docker AMI builder"
  vpc_id      = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.builder_name}-sg"
  }
}


# ========================================================
# 1. 최신 Amazon Linux 2023으로 Builder EC2 생성
# ========================================================

resource "aws_instance" "ami_builder" {
  ami           = local.base_ami_id
  instance_type = local.builder_instance_type

  subnet_id = local.builder_subnet_id

  associate_public_ip_address = false

  vpc_security_group_ids = [
    aws_security_group.ami_builder.id
  ]

  iam_instance_profile = aws_iam_instance_profile.builder.name

  user_data                   = local.builder_user_data
  user_data_replace_on_change = true

  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name    = local.builder_name
    Purpose = "Docker-AMI-Builder"
  }

  depends_on = [
    aws_iam_role_policy_attachment.builder
  ]
}


# ========================================================
# 2. User Data 완료 확인
#
# EC2가 만들어졌다고 Docker 설치가 끝난 것은 아니므로
# SSM으로 cloud-init + Docker + Compose까지 확인
# ========================================================

resource "aws_ssm_association" "ami_ready" {
  name = "AWS-RunShellScript"

  association_name = "${local.builder_name}-ready"

  parameters = {
    commands = local.ami_validation_command
  }

  targets {
    key = "InstanceIds"

    values = [
      aws_instance.ami_builder.id
    ]
  }

  wait_for_success_timeout_seconds = 1200

  depends_on = [
    aws_instance.ami_builder
  ]
}


# ========================================================
# 3. 설치 완료된 Builder 정지
# ========================================================

resource "aws_ec2_instance_state" "ami_builder_stopped" {
  instance_id = aws_instance.ami_builder.id

  state = "stopped"

  depends_on = [
    aws_ssm_association.ami_ready
  ]
}


# ========================================================
# 4. 정지된 EC2로 Custom Docker AMI 생성
# ========================================================

resource "aws_ami_from_instance" "docker" {
  name = "${local.name}-docker-${replace(
    aws_instance.ami_builder.id,
    "i-",
    ""
  )}"

  source_instance_id = aws_instance.ami_builder.id

  snapshot_without_reboot = false

  tags = {
    Name    = "${local.name}-docker-ami"
    BaseOS  = "AmazonLinux2023"
    Docker  = "Installed"
    Compose = "Installed"
  }

  depends_on = [
    aws_ec2_instance_state.ami_builder_stopped
  ]
}