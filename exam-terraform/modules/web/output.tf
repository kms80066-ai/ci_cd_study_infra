output "alb_dns_name" {
  value = aws_lb.nginx.dns_name
}
output "alb_arn_suffix" {
  value = aws_lb.nginx.arn_suffix
}
output "asg_name" {
  value = aws_autoscaling_group.nginx.name
}

