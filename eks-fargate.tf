# ==============================================================================
# EKS Fargate Profile
# ==============================================================================

resource "aws_eks_fargate_profile" "batch" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "${local.name_prefix}-batch"
  pod_execution_role_arn = aws_iam_role.eks_fargate.arn
  subnet_ids             = local.private_app_subnet_ids

  selector {
    namespace = "batch"
    labels = {
      compute = "fargate"
    }
  }

  selector {
    namespace = "kube-system"
    labels = {
      k8s-app = "kube-dns"
    }
  }

  tags = {
    Name = "${local.name_prefix}-fargate-batch"
  }
}
