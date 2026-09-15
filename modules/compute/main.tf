resource "aws_instance" "this" {
  ami                         = local.ami_id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = local.security_group_ids
  key_name                    = local.key_name
  user_data                   = local.user_data
  user_data_replace_on_change = true

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  # 추가 EBS 5GiB. 파일시스템 생성/포맷은 아직 하지 않습니다.
  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = 5
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = local.name
  }
}


# resource "aws_instance" "ec2_instance" {
#   ami           = local.ami_id
#   instance_type = "t3.micro"

#   # 퍼블릭 서브넷의 ID를 참조하여 연결합니다.
#   subnet_id = local.subnet_id
#   # 퍼블릭 IP 활성화
#   associate_public_ip_address = true
#   # NAT 인스턴스 필수 설정: 소스/대상 확인 비활성화
#   source_dest_check = false

#   # 볼륨 지정
#   root_block_device {
#     volume_size           = 10
#     volume_type           = "gp3"
#     delete_on_termination = true # 인스턴스 삭제 시 함께 삭제
#   }

#   key_name = local.key_name

#   # 보안 그룹 정의
#   vpc_security_group_ids = local.security_group_ids


#   # User Data
#   user_data = <<-EOF
# #!/bin/bash
# apt update && apt install -y nginx unzip
# EOF
#   tags      = { Name = "another-instance" }
# }


