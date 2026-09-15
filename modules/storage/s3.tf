resource "aws_s3_bucket" "this" {
  for_each = local.bucket_types

  bucket        = "${local.bucket_prefix}-${each.key}"
  force_destroy = false

  tags = {
    Name = "${local.tag_header}${each.key}-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = aws_s3_bucket.this

  bucket                  = each.value.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = each.key != "website"
  restrict_public_buckets = each.key != "website"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = aws_s3_bucket.this
  bucket   = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this["website"].id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket     = aws_s3_bucket.this["website"].id
  depends_on = [aws_s3_bucket_public_access_block.this]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.this["website"].arn}/*"
    }]
  })
}

resource "aws_s3_object" "page" {
  for_each = local.website_pages

  bucket       = aws_s3_bucket.this["website"].id
  key          = each.key
  content      = each.value
  content_type = "text/html; charset=utf-8"
}

# 로그 버킷은 보관용까지만 생성합니다.
# 로그를 보내는 서비스의 정책/설정은 이후 단계에서 연결합니다.
