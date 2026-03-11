# ==============================================================================
# Bastion Host (Auto Scaling Group + SSM)
# ==============================================================================

resource "aws_launch_template" "bastion" {
  name_prefix   = "${local.name_prefix}-bastion-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.bastion_instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.bastion.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.bastion.id]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = aws_kms_key.ebs.arn
      delete_on_termination = true
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent

    # Install kubectl
    curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/

    # Install helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # Install aws cli v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.name_prefix}-bastion"
    }
  }

  tags = { Name = "${local.name_prefix}-bastion-lt" }
}

resource "aws_autoscaling_group" "bastion" {
  name                = "${local.name_prefix}-bastion-asg"
  desired_capacity    = 1
  max_size            = 1
  min_size            = 0
  vpc_zone_identifier = local.private_app_subnet_ids

  launch_template {
    id      = aws_launch_template.bastion.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-bastion"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_schedule" "bastion_scale_down" {
  scheduled_action_name  = "scale-down-nights"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  recurrence             = "0 22 * * *"
  autoscaling_group_name = aws_autoscaling_group.bastion.name
  time_zone              = "America/Sao_Paulo"
}

resource "aws_autoscaling_schedule" "bastion_scale_up" {
  scheduled_action_name  = "scale-up-morning"
  min_size               = 0
  max_size               = 1
  desired_capacity       = 1
  recurrence             = "0 8 * * 1-5"
  autoscaling_group_name = aws_autoscaling_group.bastion.name
  time_zone              = "America/Sao_Paulo"
}
