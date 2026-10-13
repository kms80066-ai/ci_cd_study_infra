data "aws_iam_policy_document" "cluster_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "node_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${local.name_prefix}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume.json
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "node" {
  name               = "${local.name_prefix}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])
  role       = aws_iam_role.node.name
  policy_arn = each.key
}

resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = local.cluster_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.cluster]
  tags       = { Name = local.cluster_name }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.name_prefix}-eks-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = local.cluster_subnet_ids

  instance_types = [local.node_instance_type]
  capacity_type  = "ON_DEMAND"
  ami_type       = "AL2023_x86_64_STANDARD"

  scaling_config {
    min_size     = local.min_size
    desired_size = local.desired_size
    max_size     = local.max_size
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [aws_iam_role_policy_attachment.node]
  tags       = { Name = "${local.name_prefix}-eks-nodes" }
}

