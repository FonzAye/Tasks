output "mount_targets" {
  value = local.mount_targets
}

output "efs_ids_by_name" {
  value = {
    for name, efs in aws_efs_file_system.this : name => efs.id
  }
}