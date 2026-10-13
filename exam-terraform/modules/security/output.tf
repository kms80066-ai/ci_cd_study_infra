output "alb_sg_id" { value = aws_security_group.this["alb"].id }
output "web_sg_id" { value = aws_security_group.this["web"].id }
output "db_sg_id"  { value = aws_security_group.this["db"].id }

