output "efs_id" { value = aws_efs_file_system.this.id }
output "efs_dns_name" { value = aws_efs_file_system.this.dns_name }
output "website_bucket" { value = aws_s3_bucket.this["website"].id }
output "logs_bucket" { value = aws_s3_bucket.this["logs"].id }
output "website_url" { value = "http://${aws_s3_bucket_website_configuration.this.website_endpoint}" }
