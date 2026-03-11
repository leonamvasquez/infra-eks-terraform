# ==============================================================================
# Transit Gateway (multi-VPC simulation)
# ==============================================================================

# INTENTIONAL_MISCONFIG: LOW - Transit Gateway without auto-accept disabled for shared attachments
resource "aws_ec2_transit_gateway" "main" {
  description                     = "Enterprise transit gateway"
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"

  tags = {
    Name = "${local.name_prefix}-tgw"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.main.id
  subnet_ids         = local.private_app_subnet_ids

  tags = {
    Name = "${local.name_prefix}-tgw-attachment"
  }
}
