locals {
  lbs = { for lb in var.load_balancers : lb.name => lb }
  lts = { for lt in var.listeners : lt.name => lt }
  tgs = { for tg in var.target_groups : tg.name => tg }
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
  for_each = local.tgs

  name        = each.value.name
  port        = each.value.port
  protocol    = each.value.protocol
  target_type = each.value.target_type
  vpc_id      = var.vpc_ids_by_name[each.value.vpc]
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
  for_each = local.lts

  load_balancer_arn = aws_lb.this[each.value.load_balancer].arn
  port              = each.value.port
  protocol          = each.value.protocol
  certificate_arn   = each.value.port == 443 ? data.aws_acm_certificate.this.arn : ""

  # Dynamic default_action block to support all action types
  dynamic "default_action" {
    for_each = [each.value.default_action]

    content {
      type = default_action.value.type

      # Forward action
      dynamic "forward" {
        for_each = default_action.value.type == "forward" ? [default_action.value.type] : []
        content {
          target_group {
            arn = aws_lb_target_group.this[default_action.value.target_group].arn
          }
        }
      }
      # Redirect action
      dynamic "redirect" {
        for_each = default_action.value.type == "redirect" ? [default_action.value.type] : []
        content {
          port        = default_action.value.redirect.port
          protocol    = default_action.value.redirect.protocol
          status_code = default_action.value.redirect.status_code
        }
      }
    }
  }
}

data "aws_acm_certificate" "this" {
  domain   = "fonz-ocg4.click"
  statuses = ["ISSUED"]
}

# Lookup the hosted zone
data "aws_route53_zone" "this" {
  name         = "fonz-ocg4.click"
  private_zone = false
}

# Create a Route 53 alias record pointing to ALB
resource "aws_route53_record" "alb_alias" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "fonz-ocg4.click" # or "www.mycoolapp.com"
  type    = "A"

  alias {
    name                   = aws_lb.this["tf-alb-task1"].dns_name
    zone_id                = aws_lb.this["tf-alb-task1"].zone_id
    evaluate_target_health = true
  }
}
