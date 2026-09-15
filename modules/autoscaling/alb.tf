# ========================================================
# Target Group
# ========================================================

resource "aws_lb_target_group" "this" {
  name = local.target_group_name

  vpc_id = local.vpc_id

  port        = 80
  protocol    = "HTTP"
  target_type = "instance"

  health_check {
    enabled = true

    protocol = "HTTP"
    port     = "traffic-port"

    path = "/"

    matcher = "200-399"

    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = local.target_group_name
  }
}


# ========================================================
# Public ALB
# ========================================================

resource "aws_lb" "this" {
  name = local.alb_name

  internal           = false
  load_balancer_type = "application"

  security_groups = [
    local.alb_security_group_id
  ]

  subnets = local.public_subnet_ids

  tags = {
    Name = local.alb_name
  }
}


# ========================================================
# HTTP Listener
# ========================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "forward"

    target_group_arn = aws_lb_target_group.this.arn
  }
}