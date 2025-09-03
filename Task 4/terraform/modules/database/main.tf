locals {
  # Construct DB configurations from the input variable `config`
  dbs = {
    for db in var.dbs : db.name => db
  }

    # Filter out DBs that already have secrets in Secrets Manager
  dbs_without_secret = {
    for id, check in data.external.check_secret_exists :
    id => local.dbs[id] if check.result.exists == "false"
  }
}

# --- External Script: Check for existing Secrets Manager entries ---
data "external" "check_secret_exists" {
  for_each = local.dbs

  # Bash script that checks whether a secret already exists for the DB
  program = ["bash", "${path.root}/scripts/check-secret.sh", each.key]
}

# --- Secrets Manager: Create new secret if it doesn't already exist ---
resource "aws_secretsmanager_secret" "db_secret" {
  for_each = local.dbs_without_secret

  name        = "db-credentials-${each.value.identifier}"
  description = "Credentials for DB ${each.value.identifier}"

  # Ensure DB instance is created before trying to store secrets
  depends_on = [aws_db_instance.database]

  # Prevent secrets from being accidentally destroyed
  # lifecycle {
  #   prevent_destroy = true
  # }
}

# --- Secrets Manager: Store actual secret values ---
resource "aws_secretsmanager_secret_version" "db_secret_value" {
  for_each = local.dbs

  # Either use the newly created secret or fallback to the existing one found by script
  secret_id = try(
    aws_secretsmanager_secret.db_secret[each.key].id,
    data.external.check_secret_exists[each.key].result.name
  )

  # Store DB connection credentials in secret as JSON
  secret_string = jsonencode({
    DB_USER = aws_db_instance.database[each.key].username
    DB_HOST = aws_db_instance.database[each.key].address
    DB_NAME = aws_db_instance.database[each.key].db_name
    DB_PASS = aws_db_instance.database[each.key].password
    DB_PORT = aws_db_instance.database[each.key].port
  })
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
  password             = random_password.db_password[each.key].result
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

# --- Password Generator: Create a secure password for each DB ---
resource "random_password" "db_password" {
  for_each = local.dbs

  length      = 16
  special     = false # Set to true for added security
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
}


# --- Parameter Group: DB engine-specific tuning parameters ---
resource "aws_db_parameter_group" "db" {
  for_each = local.dbs

  name   = "${each.value.engine}-${replace(each.value.engine_version, ".", "")}-parameters"
  family = "${each.value.engine}${each.value.engine_version}"
}
