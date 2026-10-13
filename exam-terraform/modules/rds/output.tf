output "db_identifier" {
  value = aws_db_instance.mysql.identifier
}
output "db_endpoint" {
  value = aws_db_instance.mysql.endpoint
}
output "master_secret_arn" {
  value = aws_db_instance.mysql.master_user_secret[0].secret_arn
}

