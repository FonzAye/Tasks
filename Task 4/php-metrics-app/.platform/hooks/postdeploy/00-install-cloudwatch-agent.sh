#!/bin/bash
set -e

# Install CloudWatch Agent and jq
dnf install -y amazon-cloudwatch-agent jq

# Copy our config file
cp .platform/files/cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Start the agent
systemctl enable amazon-cloudwatch-agent
systemctl restart amazon-cloudwatch-agent
