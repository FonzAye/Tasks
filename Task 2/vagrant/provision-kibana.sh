#!/usr/bin/env bash
set -e

echo "[*] Installing Elasticsearch & Kibana..."
sudo apt-get update
sudo apt-get install -y apt-transport-https openjdk-11-jdk wget gnupg

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo sh -c 'echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" > /etc/apt/sources.list.d/elastic-7.x.list'

sudo apt-get update
sudo apt-get install -y elasticsearch kibana

# Bind to private IP
sudo sed -i 's/#server.host: "localhost"/server.host: "192.168.56.10"/' /etc/kibana/kibana.yml
sudo sed -i 's/#network.host: .*/network.host: 192.168.56.10/' /etc/elasticsearch/elasticsearch.yml

sudo systemctl enable elasticsearch kibana
sudo systemctl start elasticsearch kibana
