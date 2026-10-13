data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${local.name_prefix}-web-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "web" {
  name = "${local.name_prefix}-web-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_launch_template" "nginx" {
  name_prefix            = "${local.name_prefix}-nginx-lt-"
  image_id               = data.aws_ssm_parameter.al2023.value
  instance_type          = local.instance_type
  vpc_security_group_ids = [local.web_sg_id]
  update_default_version = true
  user_data              = base64encode(templatefile("${path.module}/user_data.sh.tftpl", {}))

  iam_instance_profile {
    name = aws_iam_instance_profile.web.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = local.volume_size
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${local.name_prefix}-nginx-node" }
  }
  tag_specifications {
    resource_type = "volume"
    tags          = { Name = "${local.name_prefix}-nginx-volume" }
  }

  depends_on = [aws_iam_role_policy_attachment.ssm]
}

resource "aws_lb" "nginx" {
  name               = local.alb_name
  internal           = false
  load_balancer_type = "application"
  subnets            = local.public_subnet_ids
  security_groups    = [local.alb_sg_id]
  tags               = { Name = local.alb_name }
}

resource "aws_lb_target_group" "nginx" {
  name        = local.tg_name
  vpc_id      = local.vpc_id
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }
  tags = { Name = local.tg_name }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.nginx.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}

resource "aws_autoscaling_group" "nginx" {
  name                      = local.asg_name
  vpc_zone_identifier       = local.private_subnet_ids
  target_group_arns         = [aws_lb_target_group.nginx.arn]
  min_size                  = local.min_size
  desired_capacity          = local.desired_size
  max_size                  = local.max_size
  health_check_type         = "ELB"
  health_check_grace_period = 600
  launch_template {
    id      = aws_launch_template.nginx.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-nginx-node"
    propagate_at_launch = true
  }

  # TargetTracking 정책이 원하는 용량을 조정하므로 plan 시 drift 제외
  lifecycle {
    ignore_changes = [desired_capacity]
  }

  depends_on = [aws_lb_listener.http]
}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "${local.asg_name}-cpu"
  autoscaling_group_name = aws_autoscaling_group.nginx.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50
  }
}

