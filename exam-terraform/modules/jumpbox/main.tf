data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jumpbox" {
  name               = "${local.name_prefix}-jumpbox-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.jumpbox.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "jumpbox" {
  name = "${local.name_prefix}-jumpbox-profile"
  role = aws_iam_role.jumpbox.name
}

resource "aws_instance" "jumpbox" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = local.instance_type
  subnet_id                   = local.public_subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [local.sg_id]
  key_name                    = local.key_name
  iam_instance_profile        = aws_iam_instance_profile.jumpbox.name

  root_block_device {
    volume_size           = local.volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  depends_on = [aws_iam_role_policy_attachment.ssm]
  tags       = { Name = "${local.name_prefix}-jumpbox" }
}
