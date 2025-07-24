output "tg_arns_by_name" {
  value = { for name, tg in aws_lb_target_group.this : name => tg.id }
}

output "acm" {
  value = data.aws_acm_certificate.this
}
