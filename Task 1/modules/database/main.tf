locals {
  # Construct DB configurations from the input variable `config`
  dbs = {
    for db in var.dbs : db.name => {
      subnet_type            = db.subnets
      network                = db.network
      identifier             = db.name
      engine                 = db.engine
      engine_version         = db.engine_version
      port                   = db.port
      allocated_storage      = db.allocated_storage
      instance_class         = db.allocated_storage
      availability_zone      = db.zone
      vpc_security_group_ids = db.security_groups
      tags                   = { Name : db.name }
    }
  }

    db_subnet_ids = merge([
    for db in local.dbs : {
      for k, subnet in var.subnets :
      k => subnet.id
      if contains(db.subnet_type, replace(k, "${db.network}-", ""))
    }
  ]...)
}

# --- DB Subnet Group: Assign DBs to relevant subnets ---
resource "aws_db_subnet_group" "my_db" {
  for_each = local.dbs

  name       = "${each.key}-subnet-group"
  subnet_ids = values(local.db_subnet_ids)

  tags = {
    Name = "${each.key}-subnet-group"
  }
}

# --- RDS Instance: Create the actual DB instances ---
resource "aws_db_instance" "database" {
  for_each = local.dbs

  allocated_storage    = each.value.allocated_storage
  identifier           = each.value.identifier
  engine               = each.value.engine
  engine_version       = each.value.engine_version
  instance_class       = each.value.instance_class
  db_name              = each.value.identifier
  username             = "admin"
  password             = "g1e2o3r4g5e6W"
  parameter_group_name = aws_db_parameter_group.db[each.key].name
  skip_final_snapshot  = true
  port                 = each.value.port
  db_subnet_group_name = aws_db_subnet_group.my_db[each.key].name
  # vpc_security_group_ids = [
  #   for key in each.value.vpc_security_group_ids : var.vpc_security_group_ids[key]
  # ]

  tags = each.value.tags
}


# --- Parameter Group: DB engine-specific tuning parameters ---
resource "aws_db_parameter_group" "db" {
  for_each = local.dbs

  name   = "${each.value.engine}${each.value.engine_version}-parameters"
  family = "${each.value.engine}${each.value.engine_version}"
}