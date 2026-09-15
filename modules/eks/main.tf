# ========================================================
# 1. EKS Cluster
# ========================================================

resource "aws_eks_cluster" "this" {
  name = local.cluster_name

  role_arn = aws_iam_role.cluster.arn

  # ======================================================
  # Network
  # ======================================================

  vpc_config {
    # EKS Control Plane ENI용 Cluster Subnet
    subnet_ids = local.cluster_subnet_ids

    # 기존 Security Module의 cluster-sg 사용
    security_group_ids = [
      local.cluster_security_group_id
    ]

    # 내부에서도 API 접근 가능
    endpoint_private_access = true

    # 학습 환경에서 Local PC의 kubectl 접근을 위해 활성화
    endpoint_public_access = true
  }


  # ======================================================
  # EKS Access
  #
  # Terraform을 실행한 IAM Principal에
  # 최초 Cluster Admin 권한 부여
  # ======================================================

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"

    bootstrap_cluster_creator_admin_permissions = true
  }


  depends_on = [
    aws_iam_role_policy_attachment.cluster
  ]


  tags = {
    Name = local.cluster_name
  }
}


# ========================================================
# 2. Worker Node Launch Template
#
# AMI는 여기서 직접 지정하지 않음.
#
# Managed Node Group에서
# AL2023_x86_64_STANDARD를 지정하면
# EKS가 적절한 EKS Optimized Amazon Linux 2023 AMI 사용
# ========================================================

resource "aws_launch_template" "node" {
  name_prefix = "${local.node_launch_template_name}-"

  # 기존 Security Module에서 만든 Worker Node SG
  vpc_security_group_ids = [
    local.node_security_group_id
  ]


  # ======================================================
  # IMDSv2
  # ======================================================

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }


  # ======================================================
  # Instance Tag
  # ======================================================

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${local.node_group_name}-instance"
    }
  }


  tag_specifications {
    resource_type = "volume"

    tags = {
      Name = "${local.node_group_name}-volume"
    }
  }
}


# ========================================================
# 3. EKS Managed Node Group
# ========================================================

resource "aws_eks_node_group" "this" {
  cluster_name = aws_eks_cluster.this.name

  node_group_name = local.node_group_name

  node_role_arn = aws_iam_role.node.arn


  # ======================================================
  # Worker Node Subnet
  #
  # Public이 아니라 Cluster Subnet
  # ======================================================

  subnet_ids = local.node_subnet_ids


  # ======================================================
  # Amazon Linux 2023 EKS Optimized AMI
  # ======================================================

  ami_type = "AL2023_x86_64_STANDARD"


  # ======================================================
  # Instance
  # ======================================================

  capacity_type = "ON_DEMAND"

  instance_types = [
    local.node_instance_type
  ]


  # ======================================================
  # PDF 요구사항
  #
  # 최소 1
  # 유지 1
  # 최대 2
  # ======================================================

  scaling_config {
    min_size     = local.min_size
    desired_size = local.desired_size
    max_size     = local.max_size
  }


  # ======================================================
  # Node Group Update
  # ======================================================

  update_config {
    max_unavailable = 1
  }


  # ======================================================
  # Worker Node Launch Template
  # ======================================================

  launch_template {
    id = aws_launch_template.node.id

    version = tostring(
      aws_launch_template.node.latest_version
    )
  }


  depends_on = [
    aws_iam_role_policy_attachment.node
  ]


  tags = {
    Name = local.node_group_name
  }
}