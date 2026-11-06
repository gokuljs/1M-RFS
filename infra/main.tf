data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

data "aws_ssm_parameter" "al2023" {
  count = var.ami_id == null ? 1 : 0
  name  = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_partition" "current" {}

locals {
  app_port = { cpeak = 3000, express = 3001 }[var.app_framework]
  ami_id   = var.ami_id != null ? var.ami_id : nonsensitive(data.aws_ssm_parameter.al2023[0].value)
  subnets = {
    for index, az in slice(data.aws_availability_zones.available.names, 0, min(2, length(data.aws_availability_zones.available.names))) :
    az => cidrsubnet(var.vpc_cidr, 4, index)
  }
  user_data = templatefile("${path.module}/templates/user-data.sh.tftpl", {
    app_repository = var.app_repository
    app_revision   = var.app_revision
    node_version   = var.node_version
    pm2_version    = var.pm2_version
    app_port       = local.app_port
    pm2_config = jsonencode({
      apps = [{
        name                      = "rfs-${var.app_framework}"
        cwd                       = "/opt/rfs/node-1m-rps"
        script                    = "${var.app_framework}.js"
        instances                 = 1
        exec_mode                 = "fork"
        node_args                 = ["--max-old-space-size=512"]
        max_memory_restart        = "650M"
        exp_backoff_restart_delay = 100
        kill_timeout              = 30000
        out_file                  = "/var/log/rfs/app.log"
        error_file                = "/var/log/rfs/error.log"
        time                      = true
        env                       = { NODE_ENV = "production" }
      }]
    })
  })
}

resource "aws_vpc" "app" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = var.project_name }

  lifecycle {
    precondition {
      condition     = length(local.subnets) == 2
      error_message = "The ALB requires two available Availability Zones."
    }
  }
}

resource "aws_internet_gateway" "app" {
  vpc_id = aws_vpc.app.id
}

resource "aws_subnet" "public" {
  for_each          = local.subnets
  vpc_id            = aws_vpc.app.id
  availability_zone = each.key
  cidr_block        = each.value
  tags              = { Name = "${var.project_name}-${each.key}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app.id
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.app.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  description = "Public HTTP and optional HTTPS entry point"
  vpc_id      = aws_vpc.app.id
}

resource "aws_security_group" "app" {
  name_prefix = "${var.project_name}-app-"
  description = "Application traffic only from the ALB; administration through SSM"
  vpc_id      = aws_vpc.app.id
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  for_each          = var.allowed_client_cidrs
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  for_each          = var.certificate_arn == null ? toset([]) : var.allowed_client_cidrs
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "app" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = local.app_port
  to_port                      = local.app_port
}

resource "aws_vpc_security_group_egress_rule" "alb" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = local.app_port
  to_port                      = local.app_port
}

resource "aws_vpc_security_group_egress_rule" "app" {
  security_group_id = aws_security_group.app.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_lb" "app" {
  name                       = var.project_name
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = [for subnet in aws_subnet.public : subnet.id]
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "app" {
  name                 = var.project_name
  port                 = local.app_port
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = aws_vpc.app.id
  deregistration_delay = 30

  health_check {
    path                = "/simple"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = var.certificate_arn == null ? "forward" : "redirect"
    target_group_arn = var.certificate_arn == null ? aws_lb_target_group.app.arn : null

    dynamic "redirect" {
      for_each = var.certificate_arn == null ? [] : [1]
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.certificate_arn == null ? 0 : 1
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_iam_role" "instance" {
  name_prefix = "${var.project_name}-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app" {
  name_prefix = "${var.project_name}-"
  role        = aws_iam_role.instance.name
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-"
  image_id      = local.ami_id
  instance_type = var.instance_type
  user_data     = base64encode(local.user_data)

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups             = [aws_security_group.app.id]
  }

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }

  monitoring {
    enabled = true
  }

  credit_specification {
    cpu_credits = var.cpu_credit_mode
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type           = "gp3"
      volume_size           = 10
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = var.project_name, Project = var.project_name }
  }
}

resource "aws_autoscaling_group" "app" {
  name_prefix               = "${var.project_name}-"
  min_size                  = var.min_instances
  desired_capacity          = var.desired_instances
  max_size                  = var.max_instances
  vpc_zone_identifier       = [for subnet in aws_subnet.public : subnet.id]
  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = max(600, var.instance_warmup_seconds)
  default_instance_warmup   = var.instance_warmup_seconds
  min_elb_capacity          = var.min_instances
  wait_for_capacity_timeout = "20m"

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 100
      max_healthy_percentage = 200
      instance_warmup        = var.instance_warmup_seconds
      skip_matching          = true
    }
  }

  lifecycle {
    ignore_changes = [desired_capacity]

    precondition {
      condition = (
        var.min_instances <= var.desired_instances &&
        var.desired_instances <= var.max_instances &&
        floor(var.desired_instances) == var.desired_instances
      )
      error_message = "Capacity must satisfy min_instances <= desired_instances <= max_instances, with integer values."
    }
  }

  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener.https,
    aws_iam_role_policy_attachment.ssm,
    aws_route.internet,
    aws_route_table_association.public,
    aws_vpc_security_group_egress_rule.app,
    aws_vpc_security_group_egress_rule.alb,
    aws_vpc_security_group_ingress_rule.app,
  ]
}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.project_name}-cpu"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value     = var.cpu_target_percent
    disable_scale_in = false
  }
}

resource "aws_autoscaling_policy" "requests" {
  count                  = var.target_requests_per_minute == null ? 0 : 1
  name                   = "${var.project_name}-requests"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.app.arn_suffix}/${aws_lb_target_group.app.arn_suffix}"
    }
    target_value     = var.target_requests_per_minute
    disable_scale_in = false
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_credits" {
  alarm_name          = "${var.project_name}-low-cpu-credits"
  alarm_description   = "Low CPU credits can throttle Standard instances and make CPU-only scaling misleading. Console alarm only; no notification destination is configured."
  namespace           = "AWS/EC2"
  metric_name         = "CPUCreditBalance"
  dimensions          = { AutoScalingGroupName = aws_autoscaling_group.app.name }
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 2
  threshold           = 10
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "notBreaching"
}
