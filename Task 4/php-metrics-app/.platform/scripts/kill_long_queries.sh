#!/bin/bash
set -e

# AWS secret details
SECRET_NAME="db-credentials-maindb"
REGION="eu-central-1"

# Fetch secret JSON from Secrets Manager
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --region $REGION --query SecretString --output text)


# Extract credentials
DB_HOST=$(echo $SECRET_JSON | jq -r '.DB_HOST')
DB_USER=$(echo $SECRET_JSON | jq -r '.DB_USER')
DB_PASS=$(echo $SECRET_JSON | jq -r '.DB_PASS')
DB_NAME=$(echo $SECRET_JSON | jq -r '.DB_NAME')

# SQL: Find long-running queries (>10s) and kill them
SQL=$(cat <<EOF
SELECT CONCAT('KILL ', id, ';')
FROM information_schema.processlist
WHERE command != 'Sleep' AND time > 10;
EOF
)

# Run SQL, then execute kills
QUERIES=$(mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -N -e "$SQL")

if [ -n "$QUERIES" ]; then
  echo "Killing queries:"
  echo "$QUERIES"
  echo "$QUERIES" | mysql -h $DB_HOST -u $DB_USER -p$DB_PASS
else
  echo "No long queries found."
fi
