# ==============================================================================
# VPC Endpoints
# ==============================================================================

# Gateway endpoints (free)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.s3"

  route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.private_app[*].id,
    [aws_route_table.private_data.id]
  )

  tags = {
    Name = "${local.name_prefix}-vpce-s3"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.dynamodb"

  route_table_ids = concat(
    aws_route_table.private_app[*].id,
    [aws_route_table.private_data.id]
  )

  tags = {
    Name = "${local.name_prefix}-vpce-dynamodb"
  }
}

# Interface endpoints
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.private_app_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name = "${local.name_prefix}-vpce-ecr-api"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.private_app_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name = "${local.name_prefix}-vpce-ecr-dkr"
  }
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.sts"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.private_app_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name = "${local.name_prefix}-vpce-sts"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.private_app_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name = "${local.name_prefix}-vpce-ssm"
  }
}

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.private_app_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name = "${local.name_prefix}-vpce-ssm-messages"
  }
}

resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.private_app_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name = "${local.name_prefix}-vpce-ec2-messages"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.private_app_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name = "${local.name_prefix}-vpce-logs"
  }
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.kms"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.private_app_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name = "${local.name_prefix}-vpce-kms"
  }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.private_app_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name = "${local.name_prefix}-vpce-secretsmanager"
  }
}
