locals {
  elastic_caches = { for elc in var.el_c : elc.name => elc }
}

# Create Redis parameter group with optimized settings
resource "aws_elasticache_parameter_group" "redis_params" {
  for_each = local.elastic_caches

  name        = each.value.parameter_group.name
  family      = each.value.parameter_group.family
  description = each.value.parameter_group.description

  parameter {
    name  = each.value.parameter_group.parameter.name
    value = each.value.parameter_group.parameter.value
  }
}

# Create the Redis replication group
resource "aws_elasticache_replication_group" "redis_cluster" {
  for_each = local.elastic_caches

  replication_group_id       = each.value.name
  description                = each.value.description
  engine                     = each.value.engine
  engine_version             = each.value.engine_version
  node_type                  = each.value.node_type
  num_cache_clusters         = each.value.num_cache_clusters
  automatic_failover_enabled = each.value.automatic_failover_enabled
  multi_az_enabled           = each.value.multi_az_enabled
  parameter_group_name       = aws_elasticache_parameter_group.redis_params[each.key].name
  subnet_group_name          = aws_elasticache_subnet_group.redis_subnet_group[each.key].name
  security_group_ids         = [for k in each.value.security_groups : var.sg_ids_by_name[k]]
  port                       = each.value.port
  apply_immediately          = each.value.apply_immediately
}

# Create subnet group for ElastiCache
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  for_each = local.elastic_caches

  name       = each.value.subnet_group.name
  subnet_ids = [for k in each.value.subnet_group.subnets : var.subnets[k]]

  tags = {
    Name = each.value.subnet_group.name
  }
}
