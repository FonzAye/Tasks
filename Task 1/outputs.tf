# output "dbs" {
#   value = module.database.dbs
# }

# output "config" {
#   value = module.network.subnets
# }

# output "test" {
#   value = module.network.test
# }

# output "vpcs" {
#   value = module.network.vpcs
# }

# output "private_subnets" {
#   value = module.network.private_subnets
# }

# output "db_subnet_ids" {
#   value = module.database.db_subnet_ids
# }

# output "mount_targets" {
#   value = module.efs.mount_targets
# }

output "efs_ids_by_name" {
  value = module.efs.efs_ids_by_name
}