output "dbs" {
  value = local.dbs
}

output "db_creds" {
  value = aws_db_instance.database
}
