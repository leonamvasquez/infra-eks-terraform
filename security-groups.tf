# ==============================================================================
# Security Groups
# ==============================================================================

# --- VPC Endpoints SG ---
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${local.name_prefix}-vpce-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for VPC endpoints"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS from VPC"
  }

  tags = {
    Name = "${local.name_prefix}-vpce-sg"
  }
}

# --- EKS Control Plane SG ---
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${local.name_prefix}-eks-cluster-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for EKS control plane"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # INTENTIONAL_MISCONFIG: HIGH - Overly broad egress on EKS cluster SG
  }

  tags = {
    Name = "${local.name_prefix}-eks-cluster-sg"
  }
}

# --- EKS Node Groups SG ---
resource "aws_security_group" "eks_nodes" {
  name_prefix = "${local.name_prefix}-eks-nodes-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for EKS worker nodes"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Node to node communication"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Outbound internet access"
  }

  tags = {
    Name = "${local.name_prefix}-eks-nodes-sg"
  }
}

# Cross-references between EKS cluster and node SGs (avoids cycle)
resource "aws_security_group_rule" "eks_cluster_ingress_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  description              = "API server access from worker nodes"
}

resource "aws_security_group_rule" "eks_nodes_ingress_control_plane" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
  description              = "Control plane to nodes"
}

resource "aws_security_group_rule" "eks_nodes_ingress_webhooks" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
  description              = "Control plane to node webhooks"
}

# --- RDS SG ---
resource "aws_security_group" "rds" {
  name_prefix = "${local.name_prefix}-rds-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for RDS Aurora"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
    description     = "PostgreSQL from EKS nodes"
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
    description     = "PostgreSQL from bastion"
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
    description     = "PostgreSQL from Lambda"
  }

  tags = {
    Name = "${local.name_prefix}-rds-sg"
  }
}

# --- ElastiCache SG ---
resource "aws_security_group" "elasticache" {
  name_prefix = "${local.name_prefix}-redis-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for ElastiCache Redis"

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
    description     = "Redis from EKS nodes"
  }

  tags = {
    Name = "${local.name_prefix}-redis-sg"
  }
}

# --- ALB SG ---
resource "aws_security_group" "alb" {
  name_prefix = "${local.name_prefix}-alb-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for public ALB"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.eks_nodes.id]
    description     = "To EKS nodes"
  }

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

# --- Internal Services SG ---
resource "aws_security_group" "internal" {
  name_prefix = "${local.name_prefix}-internal-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for internal services"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "All traffic from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "All traffic to VPC"
  }

  tags = {
    Name = "${local.name_prefix}-internal-sg"
  }
}

# --- Bastion SG ---
resource "aws_security_group" "bastion" {
  name_prefix = "${local.name_prefix}-bastion-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for bastion host"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # INTENTIONAL_MISCONFIG: CRITICAL - SSH open to the world
    description = "SSH access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Outbound access"
  }

  tags = {
    Name = "${local.name_prefix}-bastion-sg"
  }
}

# --- Lambda SG ---
resource "aws_security_group" "lambda" {
  name_prefix = "${local.name_prefix}-lambda-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for Lambda functions"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Outbound access"
  }

  tags = {
    Name = "${local.name_prefix}-lambda-sg"
  }
}

# --- OpenSearch SG ---
resource "aws_security_group" "opensearch" {
  name_prefix = "${local.name_prefix}-opensearch-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
    description     = "HTTPS from EKS nodes"
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  } # INTENTIONAL_MISCONFIG: MEDIUM - Missing description on SG rule

  tags = {
    Name = "${local.name_prefix}-opensearch-sg"
  }
}

# --- NLB SG ---
resource "aws_security_group" "nlb" {
  name_prefix = "${local.name_prefix}-nlb-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for internal NLB"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "gRPC/HTTPS from VPC"
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.eks_nodes.id]
    description     = "To EKS nodes"
  }

  tags = {
    Name = "${local.name_prefix}-nlb-sg"
  }
}
