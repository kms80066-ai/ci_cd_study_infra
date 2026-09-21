locals {
  # ========================================================
  # Input
  # ========================================================

  cluster_name = var.cluster_name
  tag_header   = var.tag_header

  cluster_subnet_ids = var.cluster_subnet_ids
  node_subnet_ids    = var.node_subnet_ids


  node_instance_type = var.node_instance_type

  min_size     = var.min_size
  desired_size = var.desired_size
  max_size     = var.max_size


  # ========================================================
  # Naming
  # ========================================================

  cluster_role_name = "${local.cluster_name}-cluster-role"
  node_role_name    = "${local.cluster_name}-node-role"

  node_group_name = "${local.tag_header}eks-node-group"

  node_launch_template_name = "${local.node_group_name}-lt"


  # ========================================================
  # EKS Cluster IAM Trust Policy
  # ========================================================

  cluster_assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "eks.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })


  # ========================================================
  # EKS Worker Node IAM Trust Policy
  # ========================================================

  node_assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })


  # ========================================================
  # Cluster IAM Policies
  # ========================================================

  cluster_policy_arns = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  ])


  # ========================================================
  # Worker Node IAM Policies
  # ========================================================

  node_policy_arns = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ])
}