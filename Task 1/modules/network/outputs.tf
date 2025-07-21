output "vpc_ids_by_name" {
  description = "Map of VPC keys to their IDs"
  value       = { for name, vpc in aws_vpc.terraform : name => vpc.id }
}

output "test" {
  value = local.test
}

output "vpcs" {
  value = local.vpcs
}

output "aws_subnets" {
  value = aws_subnet.subnets
}

output "subnets" {
  value = aws_subnet.subnets
}