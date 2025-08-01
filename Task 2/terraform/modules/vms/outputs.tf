output "private_ips" {
  value = { for k, vm in aws_instance.vm : k => vm.private_ip }
}

output "public_dns_names" {
  value = { for k, vm in aws_instance.vm : k => vm.public_dns }
}

output "node_names" {
  value = { for k, vm in local.vms : k => vm.name }
}
