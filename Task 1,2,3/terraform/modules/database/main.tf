locals {
  # Construct DB configurations from the input variable `config`
  dbs = {
    for db in var.dbs : db.name => db
  }
}

# --- DB Subnet Group: Assign DBs to relevant subnets ---
resource "aws_db_subnet_group" "my_db" {
  for_each = local.dbs

  name = "${each.key}-subnet-group"
  subnet_ids = [
    for k in each.value.subnets : var.subnets[k]
  ]

  tags = {
    Name = "${each.key}-subnet-group"
  }
}

# --- RDS Instance: Create the actual DB instances ---
resource "aws_db_instance" "database" {
  for_each = local.dbs

  allocated_storage    = each.value.allocated_storage
  identifier           = each.value.name
  engine               = each.value.engine
  engine_version       = each.value.engine_version
  instance_class       = each.value.instance_class
  db_name              = each.value.name
  username             = "admin"
  password             = "g1e2o3r4g5e6W"
  parameter_group_name = aws_db_parameter_group.db[each.key].name
  skip_final_snapshot  = true
  publicly_accessible  = true
  port                 = each.value.port
  db_subnet_group_name = aws_db_subnet_group.my_db[each.key].name
  vpc_security_group_ids = [
    for key in each.value.security_groups : var.sg_ids_by_name[key]
  ]

  tags = {
    Name = each.value.name
  }
}


# --- Parameter Group: DB engine-specific tuning parameters ---
resource "aws_db_parameter_group" "db" {
  for_each = local.dbs

  name   = "${each.value.engine}-${replace(each.value.engine_version, ".", "")}-parameters"
  family = "${each.value.engine}${each.value.engine_version}"
}
