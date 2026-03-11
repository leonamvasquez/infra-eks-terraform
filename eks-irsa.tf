# ==============================================================================
# IRSA (IAM Roles for Service Accounts)
# ==============================================================================

# --- ALB Ingress Controller ---
resource "aws_iam_role" "alb_controller" {
  name = "${local.name_prefix}-alb-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = { Name = "${local.name_prefix}-alb-controller" }
}

resource "aws_iam_role_policy" "alb_controller" {
  name = "${local.name_prefix}-alb-controller-policy"
  role = aws_iam_role.alb_controller.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeAvailabilityZones",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup",
          "iam:CreateServiceLinkedRole",
          "cognito-idp:DescribeUserPoolClient",
          "waf-regional:GetWebACL",
          "waf-regional:AssociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:AssociateWebACL",
          "shield:GetSubscriptionState",
          "acm:ListCertificates",
          "acm:DescribeCertificate"
        ]
        Resource = "*"
      }
    ]
  })
}

# --- External DNS ---
resource "aws_iam_role" "external_dns" {
  name = "${local.name_prefix}-external-dns"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:external-dns"
        }
      }
    }]
  })

  tags = { Name = "${local.name_prefix}-external-dns" }
}

resource "aws_iam_role_policy" "external_dns" {
  name = "${local.name_prefix}-external-dns-policy"
  role = aws_iam_role.external_dns.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets"]
        Resource = "arn:${data.aws_partition.current.partition}:route53:::hostedzone/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ]
        Resource = "*"
      }
    ]
  })
}

# --- Cert Manager ---
resource "aws_iam_role" "cert_manager" {
  name = "${local.name_prefix}-cert-manager"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_url}:sub" = "system:serviceaccount:cert-manager:cert-manager"
        }
      }
    }]
  })

  tags = { Name = "${local.name_prefix}-cert-manager" }
}

resource "aws_iam_role_policy" "cert_manager" {
  name = "${local.name_prefix}-cert-manager-policy"
  role = aws_iam_role.cert_manager.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:GetChange"]
        Resource = "arn:${data.aws_partition.current.partition}:route53:::change/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:route53:::hostedzone/*"
      },
      {
        Effect   = "Allow"
        Action   = ["route53:ListHostedZonesByName"]
        Resource = "*"
      }
    ]
  })
}

# --- Cluster Autoscaler ---
resource "aws_iam_role" "cluster_autoscaler" {
  name = "${local.name_prefix}-cluster-autoscaler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
        }
      }
    }]
  })

  tags = { Name = "${local.name_prefix}-cluster-autoscaler" }
}

resource "aws_iam_role_policy" "cluster_autoscaler" {
  name = "${local.name_prefix}-cluster-autoscaler-policy"
  role = aws_iam_role.cluster_autoscaler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeInstanceTypes",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      }
    ]
  })
}

# --- Fluent Bit ---
resource "aws_iam_role" "fluent_bit" {
  name = "${local.name_prefix}-fluent-bit"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_url}:sub" = "system:serviceaccount:logging:fluent-bit"
        }
      }
    }]
  })

  tags = { Name = "${local.name_prefix}-fluent-bit" }
}

resource "aws_iam_role_policy" "fluent_bit" {
  name = "${local.name_prefix}-fluent-bit-policy"
  role = aws_iam_role.fluent_bit.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:*"
    }]
  })
}

# --- EBS CSI Driver ---
resource "aws_iam_role" "ebs_csi_driver" {
  name = "${local.name_prefix}-ebs-csi-driver"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })

  tags = { Name = "${local.name_prefix}-ebs-csi-driver" }
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
