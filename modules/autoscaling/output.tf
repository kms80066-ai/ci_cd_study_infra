output "builder_instance_id" {
  value = aws_instance.ami_builder.id
}

output "docker_ami_id" {
  value = aws_ami_from_instance.docker.id
}

output "docker_ami_name" {
  value = aws_ami_from_instance.docker.name
}

output "launch_template_id" {
  value = aws_launch_template.this.id
}

output "asg_name" {
  value = aws_autoscaling_group.this.name
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.this.arn
}

output "ecr_repository_urls" {
  value = {
    for name, repository in aws_ecr_repository.this :
    name => repository.repository_url
  }
}