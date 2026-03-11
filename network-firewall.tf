# ==============================================================================
# AWS Network Firewall
# ==============================================================================

# INTENTIONAL_MISCONFIG: MEDIUM - Network Firewall without logging configuration
resource "aws_networkfirewall_firewall" "main" {
  name                = "${local.name_prefix}-network-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.main.arn
  vpc_id              = aws_vpc.main.id

  dynamic "subnet_mapping" {
    for_each = local.public_subnet_ids
    content {
      subnet_id = subnet_mapping.value
    }
  }

  tags = {
    Name = "${local.name_prefix}-network-firewall"
  }
}

resource "aws_networkfirewall_firewall_policy" "main" {
  name = "${local.name_prefix}-firewall-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.block_domains.arn
    }
  }

  tags = {
    Name = "${local.name_prefix}-firewall-policy"
  }
}

resource "aws_networkfirewall_rule_group" "block_domains" {
  capacity = 100
  name     = "${local.name_prefix}-block-domains"
  type     = "STATEFUL"

  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [var.vpc_cidr]
        }
      }
    }

    rules_source {
      rules_source_list {
        generated_rules_type = "DENYLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = [".malware.example.com", ".phishing.example.com"]
      }
    }
  }

  tags = {
    Name = "${local.name_prefix}-block-domains"
  }
}
