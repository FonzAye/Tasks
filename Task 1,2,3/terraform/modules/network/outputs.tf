output "vpc_ids_by_name" {
  description = "Map of VPC keys to their IDs"
  value       = { for name, vpc in aws_vpc.terraform : name => vpc.id }
}

output "subnets" {
  value = { for name, subnet in aws_subnet.subnets : name => subnet.id }
}

output "private_subnets" {
  value = {
    for name, subnet in aws_subnet.subnets :
    name => subnet.id
    if can(regex("private", name))
  }
}

output "public_subnets" {
  value = {
    for name, subnet in aws_subnet.subnets :
    name => subnet.id
    if can(regex("public", name))
  }
}
