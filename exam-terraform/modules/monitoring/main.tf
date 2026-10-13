# CloudWatch 기본 지표 대시보드. Grafana는 별도 인증/연결 결정 후 추가.
resource "aws_cloudwatch_dashboard" "exam" {
  dashboard_name = "${local.name_prefix}-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Nginx ASG CPU"
          region  = local.region
          period  = 300
          stat    = "Average"
          metrics = [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", local.asg_name]]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "ALB Requests"
          region  = local.region
          period  = 300
          stat    = "Sum"
          metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.alb_arn_suffix]]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "RDS MySQL CPU"
          region  = local.region
          period  = 300
          stat    = "Average"
          metrics = [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", local.rds_identifier]]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "RDS Free Storage"
          region  = local.region
          period  = 300
          stat    = "Average"
          metrics = [["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", local.rds_identifier]]
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${local.name_prefix}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU over 80% for 10 minutes (no notification target)"
  dimensions          = { DBInstanceIdentifier = local.rds_identifier }
}

