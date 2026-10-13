output "public_ip" {
  value = aws_instance.jumpbox.public_ip
}
output "public_dns" {
  value = aws_instance.jumpbox.public_dns
}
output "instance_id" {
  value = aws_instance.jumpbox.id
}
