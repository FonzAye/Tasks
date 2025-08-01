#!/bin/bash

# Exit immediately if a command fails, treat unset variables as errors, and fail on pipe errors
set -euo pipefail

# Update all packages
sudo yum update -y

# Import Amazon Corretto GPG key and add its repository
sudo rpm --import https://yum.corretto.aws/corretto.key
sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo

# Install Amazon Corretto 11 (Java 11)
sudo yum install -y java-11-amazon-corretto
java -version  # Optional: confirm installation

# Import Elasticsearch GPG key
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

# Add the Elasticsearch yum repository
sudo tee /etc/yum.repos.d/elasticsearch.repo > /dev/null <<EOF
[elasticsearch]
name=Elasticsearch repository
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

echo "Installing Elasticsearch..."

# Install Elasticsearch
sudo yum install -y elasticsearch

# # Enable and start Elasticsearch service
# sudo systemctl enable elasticsearch
# sudo systemctl start elasticsearch

# # Script to update Elasticsearch configuration
# CONFIG_FILE="/etc/elasticsearch/elasticsearch.yml"
# BACKUP_FILE="${CONFIG_FILE}.bak"

# # --- Step 1: Check if config file exists ---
# sudo test -f "$CONFIG_FILE" || { echo "ERROR: Config file not found"; exit 1; }

# # --- Step 2: Create a backup ---
# cp "$CONFIG_FILE" "$BACKUP_FILE"
# echo "Backup created: $BACKUP_FILE"

# # --- Step 3: Apply changes using sed ---
# echo "Applying configuration changes..."

# CHANGED=false

# # 1. Set network.host to 0.0.0.0
# if grep -qE '^#?network\.host:' "$CONFIG_FILE"; then
#   sed -i 's|^#\?network\.host:.*|network.host: 0.0.0.0|' "$CONFIG_FILE"
#   CHANGED=true
# fi

# # 2. Set discovery.seed_hosts to an empty array
# if grep -qE '^#?discovery\.seed_hosts:' "$CONFIG_FILE"; then
#   sed -i 's|^#\?discovery\.seed_hosts:.*|discovery.seed_hosts: []|' "$CONFIG_FILE"
#   CHANGED=true
# fi

# # 3. Disable xpack.security.enabled
# if grep -qE '^#?xpack\.security\.enabled:' "$CONFIG_FILE"; then
#   sed -i 's|^#\?xpack\.security\.enabled:.*|xpack.security.enabled: false|' "$CONFIG_FILE"
#   CHANGED=true
# else
#   echo "xpack.security.enabled: false" >> "$CONFIG_FILE"
#   CHANGED=true
# fi

# # --- Step 4: Validate the YAML syntax ---
# echo "Validating YAML syntax..."
# if ! python3 -c "import yaml, sys; yaml.safe_load(open('$CONFIG_FILE'))" 2>/dev/null; then
#   echo "ERROR: Invalid YAML syntax in $CONFIG_FILE"
#   echo "Restoring backup..."
#   cp "$BACKUP_FILE" "$CONFIG_FILE"
#   exit 2
# fi

# # --- Step 5: Restart Elasticsearch if changes were made ---
# if [ "$CHANGED" = true ]; then
#   echo "Restarting Elasticsearch..."
#   sudo systemctl daemon-reexec
#   sudo systemctl restart elasticsearch

#   if systemctl is-active --quiet elasticsearch; then
#     echo "Elasticsearch restarted successfully."
#     echo "Changes applied:"
#     echo " - network.host: 0.0.0.0"
#     echo " - discovery.seed_hosts: []"
#     echo " - xpack.security.enabled: false"
#   else
#     echo "ERROR: Failed to restart Elasticsearch."
#     exit 3
#   fi
# else
#   echo "No changes were made to the configuration."
# fi

# sudo yum install logstash -y

# sudo tee /etc/logstash/conf.d/logstash.conf > /dev/null <<EOF
# input {
#   beats {
#     port => 5044
#   }
# }
# output {
#   if [@metadata][pipeline] {
# 	elasticsearch {
#   	hosts => ["localhost:9200"]
#   	manage_template => false
#   	index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
#   	pipeline => "%{[@metadata][pipeline]}"
# 	}
#   } else {
# 	elasticsearch {
#   	hosts => ["localhost:9200"]
#   	manage_template => false
#   	index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
# 	}
#   }
# }
# EOF

# sudo systemctl enable logstash
# sudo systemctl start logstash

# sudo yum install kibana -y

# sudo systemctl enable kibana
# sudo systemctl start kibana

