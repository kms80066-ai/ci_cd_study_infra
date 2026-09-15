# ========================================================
# EKS Cluster IAM Role
# ========================================================

resource "aws_iam_role" "cluster" {
  name = local.cluster_role_name

  assume_role_policy = local.cluster_assume_role_policy

  tags = {
    Name = local.cluster_role_name
  }
}


# ========================================================
# EKS Cluster IAM Policy Attachment
# ========================================================

resource "aws_iam_role_policy_attachment" "cluster" {
  for_each = local.cluster_policy_arns

  role       = aws_iam_role.cluster.name
  policy_arn = each.value
}


# ========================================================
# EKS Worker Node IAM Role
# ========================================================

resource "aws_iam_role" "node" {
  name = local.node_role_name

  assume_role_policy = local.node_assume_role_policy

  tags = {
    Name = local.node_role_name
  }
}


# ========================================================
# EKS Worker Node IAM Policy Attachment
# ========================================================

resource "aws_iam_role_policy_attachment" "node" {
  for_each = local.node_policy_arns

  role       = aws_iam_role.node.name
  policy_arn = each.value
}