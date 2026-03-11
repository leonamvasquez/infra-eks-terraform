# ==============================================================================
# EKS Managed Node Groups
# ==============================================================================

# --- System Node Group ---
resource "aws_launch_template" "eks_system" {
  name_prefix = "${local.name_prefix}-eks-system-"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 50
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = aws_kms_key.ebs.arn
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name     = "${local.name_prefix}-eks-system-node"
      NodeType = "system"
    })
  }

  tags = {
    Name = "${local.name_prefix}-eks-system-lt"
  }
}

resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.name_prefix}-system"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = local.private_app_subnet_ids
  instance_types  = var.eks_system_instance_types

  launch_template {
    id      = aws_launch_template.eks_system.id
    version = aws_launch_template.eks_system.latest_version
  }

  scaling_config {
    desired_size = var.eks_system_desired_size
    max_size     = var.eks_system_desired_size * 2
    min_size     = 1
  }

  labels = {
    role = "system"
  }

  tags = {
    Name = "${local.name_prefix}-system-ng"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_ecr_read,
  ]
}

# --- App Node Group ---
resource "aws_launch_template" "eks_app" {
  name_prefix = "${local.name_prefix}-eks-app-"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 100
      volume_type           = "gp3"
      encrypted             = false # INTENTIONAL_MISCONFIG: HIGH - EBS volume without encryption
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional" # INTENTIONAL_MISCONFIG: MEDIUM - IMDSv2 not enforced
    http_put_response_hop_limit = 2
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name     = "${local.name_prefix}-eks-app-node"
      NodeType = "app"
    })
  }

  tags = {
    Name = "${local.name_prefix}-eks-app-lt"
  }
}

resource "aws_eks_node_group" "app" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.name_prefix}-app"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = local.private_app_subnet_ids
  instance_types  = var.eks_app_instance_types

  launch_template {
    id      = aws_launch_template.eks_app.id
    version = aws_launch_template.eks_app.latest_version
  }

  scaling_config {
    desired_size = var.eks_app_desired_size
    max_size     = var.eks_app_desired_size * 3
    min_size     = 2
  }

  labels = {
    role = "app"
  }

  tags = {
    Name = "${local.name_prefix}-app-ng"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_ecr_read,
  ]
}

# --- GPU Node Group ---
resource "aws_launch_template" "eks_gpu" {
  name_prefix = "${local.name_prefix}-eks-gpu-"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 200
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = aws_kms_key.ebs.arn
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name     = "${local.name_prefix}-eks-gpu-node"
      NodeType = "gpu"
    })
  }

  tags = {
    Name = "${local.name_prefix}-eks-gpu-lt"
  }
}

resource "aws_eks_node_group" "gpu" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.name_prefix}-gpu"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = local.private_app_subnet_ids
  instance_types  = var.eks_gpu_instance_types
  ami_type        = "AL2_x86_64_GPU"

  launch_template {
    id      = aws_launch_template.eks_gpu.id
    version = aws_launch_template.eks_gpu.latest_version
  }

  scaling_config {
    desired_size = var.eks_gpu_desired_size
    max_size     = max(var.eks_gpu_desired_size * 2, 1)
    min_size     = 0
  }

  labels = {
    role                         = "gpu"
    "nvidia.com/gpu.accelerator" = "true"
  }

  taint {
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  tags = {
    Name = "${local.name_prefix}-gpu-ng"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_ecr_read,
  ]
}
