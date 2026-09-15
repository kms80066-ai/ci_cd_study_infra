# ========================================================
# Launch Template
# ========================================================

resource "aws_launch_template" "this" {
  name_prefix = "${local.name}-lt-"

  update_default_version = true

  # ======================================================
  # Terraform이 직접 만든 Docker AMI
  # ======================================================

  image_id = aws_ami_from_instance.docker.id

  instance_type = local.asg_instance_type

  vpc_security_group_ids = local.instance_security_group_ids

  iam_instance_profile {
    name = aws_iam_instance_profile.asg.name
  }

  user_data = base64encode(local.asg_user_data)

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # GitHub Actions SSM Target
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${local.name}-instance"
      Cicd = "asg"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name = "${local.name}-volume"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.asg
  ]
}


# ========================================================
# Auto Scaling Group
# ========================================================

resource "aws_autoscaling_group" "this" {
  name = local.name

  # Private 1a / 1b / 1d
  vpc_zone_identifier = local.private_subnet_ids

  min_size         = local.min_size
  desired_capacity = local.desired_capacity
  max_size         = local.max_size

  target_group_arns = [
    aws_lb_target_group.this.arn
  ]

  # 최초 Terraform apply 시에는 아직 GitHub Actions가
  # 실행되지 않아 nginx가 없을 수 있음.
  #
  # 이때 ALB Health Check 때문에 ASG가 EC2를 계속
  # 제거/재생성하지 않도록 ASG 자체 Health Check는 EC2 사용.
  health_check_type         = "EC2"
  health_check_grace_period = 300
  lifecycle {
  ignore_changes = [
    desired_capacity
  ]
}
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name}-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Cicd"
    value               = "asg"
    propagate_at_launch = true
  }

  depends_on = [
    aws_lb_listener.http
  ]
}
resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "${local.name}-cpu-policy"
  autoscaling_group_name = aws_autoscaling_group.this.name

  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}