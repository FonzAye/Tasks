#!/bin/bash
set -e

# Secret name in AWS Secrets Manager
SECRET_NAME="db-credentials-maindb"
REGION="eu-central-1"

# Get secret JSON from AWS Secrets Manager
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --region $REGION --query SecretString --output text)

# Extract values from JSON
DB_HOST=$(echo $SECRET_JSON | jq -r '.DB_HOST')
DB_USER=$(echo $SECRET_JSON | jq -r '.DB_USER')
DB_PASS=$(echo $SECRET_JSON | jq -r '.DB_PASS')
DB_NAME=$(echo $SECRET_JSON | jq -r '.DB_NAME')

# Path to dump file in EB app
DUMP_FILE="employees.sql"

echo "Restoring employees DB to RDS ($DB_HOST)..."

cd /var/app/current/test_db/

mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME < $DUMP_FILE

echo "Restore finished!"
