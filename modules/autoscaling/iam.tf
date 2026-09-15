# ========================================================
# AMI Builder IAM Role
# ========================================================

resource "aws_iam_role" "builder" {
  name = local.builder_role_name

  assume_role_policy = local.ec2_assume_role_policy

  tags = {
    Name = local.builder_role_name
  }
}


resource "aws_iam_role_policy_attachment" "builder" {
  for_each = local.builder_policy_arns

  role       = aws_iam_role.builder.name
  policy_arn = each.value
}


resource "aws_iam_instance_profile" "builder" {
  name = local.builder_instance_profile
  role = aws_iam_role.builder.name
}


# ========================================================
# ASG EC2 IAM Role
# ========================================================

resource "aws_iam_role" "asg" {
  name = local.asg_role_name

  assume_role_policy = local.ec2_assume_role_policy

  tags = {
    Name = local.asg_role_name
  }
}


resource "aws_iam_role_policy_attachment" "asg" {
  for_each = local.asg_policy_arns

  role       = aws_iam_role.asg.name
  policy_arn = each.value
}


resource "aws_iam_instance_profile" "asg" {
  name = local.asg_instance_profile
  role = aws_iam_role.asg.name
}