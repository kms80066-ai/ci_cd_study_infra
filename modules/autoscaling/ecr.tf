resource "aws_ecr_repository" "this" {
  for_each = local.ecr_repository_names

  name = each.value

  image_tag_mutability = "MUTABLE"

  # 학습 환경에서 terraform destroy가
  # 이미지 때문에 실패하지 않도록 설정
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = each.value
  }
}