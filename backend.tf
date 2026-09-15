# 기존 수업용 상태 버킷과 잠금 테이블을 그대로 사용합니다.
terraform {
  backend "s3" {
    bucket         = "bipa17-std09-terraform-state-bucket"
    key            = "TerraformState/Lab/module_0911/terraform.tfstate"
    region         = "ca-central-1"
    dynamodb_table = "std09-lab-lock-table"
    encrypt        = true
  }
}
