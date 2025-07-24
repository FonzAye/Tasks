locals {
  lbs = { for lb in var.load_balancers : lb.name => lb }
}

# Create an application load balancer
resource "aws_lb" "this" {
  for_each = local.lbs

  name               = each.value.name
  internal           = each.value.internal
  load_balancer_type = each.value.load_balancer_type

  subnets = [
    for k in each.value.subnets : var.subnets[k]
  ]

  security_groups = [
    for k in each.value.security_groups : var.sg_ids_by_name[k]
  ]

  tags = {
    Name = each.value.name
  }
}

# Create a load balancer target group
resource "aws_lb_target_group" "this" {
  for_each = local.lbs

  name        = each.value.target_group.name
  port        = each.value.target_group.port
  protocol    = each.value.target_group.protocol
  target_type = each.value.target_group.target_type
  vpc_id      = var.vpc_ids_by_name[each.value.target_group.vpc]
  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

# Add listener to load balancer
resource "aws_lb_listener" "this" {
  for_each = local.lbs

  load_balancer_arn = aws_lb.this[each.value.name].arn
  port              = each.value.listener.port
  protocol          = each.value.listener.protocol

  default_action {
    type             = each.value.listener.default_action.type
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }
}

