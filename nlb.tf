# ==============================================================================
# Network Load Balancer (Internal)
# ==============================================================================

resource "aws_lb" "internal" {
  name               = "${local.name_prefix}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = local.private_app_subnet_ids

  enable_deletion_protection       = true
  enable_cross_zone_load_balancing = true

  tags = { Name = "${local.name_prefix}-nlb" }
}

resource "aws_lb_listener" "grpc" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "9090"
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grpc.arn
  }

  tags = { Name = "${local.name_prefix}-grpc-listener" }
}

resource "aws_lb_target_group" "grpc" {
  name        = "${local.name_prefix}-grpc-tg"
  port        = 9090
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 30
    port                = "traffic-port"
    protocol            = "TCP"
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  tags = { Name = "${local.name_prefix}-grpc-tg" }
}

resource "aws_lb_listener" "tcp_services" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "8443"
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tcp_services.arn
  }

  tags = { Name = "${local.name_prefix}-tcp-services-listener" }
}

resource "aws_lb_target_group" "tcp_services" {
  name        = "${local.name_prefix}-tcp-svc-tg"
  port        = 8443
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 30
    port                = "traffic-port"
    protocol            = "TCP"
    unhealthy_threshold = 3
  }

  tags = { Name = "${local.name_prefix}-tcp-services-tg" }
}
