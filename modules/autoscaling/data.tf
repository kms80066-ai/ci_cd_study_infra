# ========================================================
# 최신 일반 Amazon Linux 2023 x86_64 AMI
#
# EKS Optimized AMI가 아님
# ========================================================

data "aws_ssm_parameter" "al2023_latest" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}