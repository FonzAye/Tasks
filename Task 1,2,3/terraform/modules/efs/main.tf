locals {
  efs = { for efs in var.efs : efs.creation_token => efs }

  mount_targets = merge([
    for efs_entry in var.efs : {
      for mt in efs_entry.mount_targets : 
      "${efs_entry.creation_token}-${mt.subnet}" => {
        subnet          = mt.subnet
        security_groups = mt.security_groups
        creation_token  = efs_entry.creation_token
      }
    }
  ]...)
}

resource "aws_efs_file_system" "this" {
  for_each = local.efs

  creation_token = each.value.creation_token
  encrypted = each.value.encrypted
  lifecycle_policy {
    transition_to_ia = each.value.lifecycle_policy.transition_to_ia
  }
  tags = each.value.tags
}

resource "aws_efs_mount_target" "this" {
  for_each = local.mount_targets

  file_system_id = aws_efs_file_system.this[each.value.creation_token].id
  subnet_id      = var.subnets[each.value.subnet]
  security_groups = [
    for k in each.value.security_groups : var.sg_ids_by_name[k]
  ]
}