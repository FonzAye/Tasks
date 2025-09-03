#!/bin/bash
set -e

# Secret name in AWS Secrets Manager
SECRET_NAME="db-credentials-maindb"
REGION="eu-central-1"

# Get secret JSON from AWS Secrets Manager
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --region $REGION --query SecretString --output text)

# Extract values from JSON
DB_HOST=$(echo $SECRET_JSON | jq -r '.host')
DB_USER=$(echo $SECRET_JSON | jq -r '.username')
DB_PASS=$(echo $SECRET_JSON | jq -r '.password')
DB_NAME=$(echo $SECRET_JSON | jq -r '.dbname')

# Path to dump file in EB app
DUMP_FILE="/var/app/current/php-metrics-app/test_db/employees.sql"

echo "Restoring employees DB to RDS ($DB_HOST)..."

mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME < $DUMP_FILE

echo "Restore finished!"
