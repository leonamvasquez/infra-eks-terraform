# ==============================================================================
# IAM Roles & Policies
# ==============================================================================

# --- EKS Cluster Role ---
resource "aws_iam_role" "eks_cluster" {
  name               = "${local.name_prefix}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json

  tags = { Name = "${local.name_prefix}-eks-cluster-role" }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSServicePolicy"
}

# --- EKS Node Role ---
resource "aws_iam_role" "eks_node" {
  name               = "${local.name_prefix}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = { Name = "${local.name_prefix}-eks-node-role" }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_read" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_ssm" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "eks_node" {
  name = "${local.name_prefix}-eks-node-profile"
  role = aws_iam_role.eks_node.name
}

# --- EKS Fargate Role ---
resource "aws_iam_role" "eks_fargate" {
  name               = "${local.name_prefix}-eks-fargate-role"
  assume_role_policy = data.aws_iam_policy_document.eks_fargate_assume_role.json

  tags = { Name = "${local.name_prefix}-eks-fargate-role" }
}

resource "aws_iam_role_policy_attachment" "eks_fargate_pod_execution" {
  role       = aws_iam_role.eks_fargate.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

# --- Bastion Role ---
resource "aws_iam_role" "bastion" {
  name               = "${local.name_prefix}-bastion-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = { Name = "${local.name_prefix}-bastion-role" }
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${local.name_prefix}-bastion-profile"
  role = aws_iam_role.bastion.name
}

# --- RDS Enhanced Monitoring Role ---
resource "aws_iam_role" "rds_monitoring" {
  name               = "${local.name_prefix}-rds-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_assume_role.json

  tags = { Name = "${local.name_prefix}-rds-monitoring-role" }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# --- Lambda Execution Role ---
resource "aws_iam_role" "lambda" {
  name               = "${local.name_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = { Name = "${local.name_prefix}-lambda-role" }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# INTENTIONAL_MISCONFIG: CRITICAL - IAM policy with Action: *
resource "aws_iam_role_policy" "lambda_overly_broad" {
  name = "${local.name_prefix}-lambda-broad-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "*"
      Resource = "*"
    }]
  })
}

# --- CodeBuild Role ---
resource "aws_iam_role" "codebuild" {
  name               = "${local.name_prefix}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json

  tags = { Name = "${local.name_prefix}-codebuild-role" }
}

resource "aws_iam_role_policy" "codebuild" {
  name = "${local.name_prefix}-codebuild-policy"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = aws_eks_cluster.main.arn
      }
    ]
  })
}

# --- CodePipeline Role ---
resource "aws_iam_role" "codepipeline" {
  name               = "${local.name_prefix}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json

  tags = { Name = "${local.name_prefix}-codepipeline-role" }
}

resource "aws_iam_role_policy" "codepipeline" {
  name = "${local.name_prefix}-codepipeline-policy"
  role = aws_iam_role.codepipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetBucketVersioning"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:UploadArchive",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:CancelUploadArchive"
        ]
        Resource = "*"
      }
    ]
  })
}

# --- Firehose Delivery Role ---
resource "aws_iam_role" "firehose" {
  name               = "${local.name_prefix}-firehose-role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json

  tags = { Name = "${local.name_prefix}-firehose-role" }
}

resource "aws_iam_role_policy" "firehose" {
  name = "${local.name_prefix}-firehose-policy"
  role = aws_iam_role.firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.logs.arn,
          "${aws_s3_bucket.logs.arn}/*"
        ]
      }
    ]
  })
}

# --- Backup Role ---
resource "aws_iam_role" "backup" {
  name               = "${local.name_prefix}-backup-role"
  assume_role_policy = data.aws_iam_policy_document.backup_assume_role.json

  tags = { Name = "${local.name_prefix}-backup-role" }
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restores" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# --- IAM Account Password Policy ---
# INTENTIONAL_MISCONFIG: MEDIUM - Weak password policy
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 8
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = false
  require_symbols                = false
  allow_users_to_change_password = true
  max_password_age               = 0
  password_reuse_prevention      = 0
}
