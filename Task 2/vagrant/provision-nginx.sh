#!/usr/bin/env bash
set -e

echo "[*] Installing Nginx & oauth2-proxy..."
sudo apt-get update
sudo apt-get install -y nginx wget tar

# Install oauth2-proxy
OAUTH2_VERSION=v7.6.0
wget https://github.com/oauth2-proxy/oauth2-proxy/releases/download/${OAUTH2_VERSION}/oauth2-proxy-${OAUTH2_VERSION}.linux-amd64.tar.gz
tar -xvzf oauth2-proxy-${OAUTH2_VERSION}.linux-amd64.tar.gz
sudo mv oauth2-proxy-${OAUTH2_VERSION}.linux-amd64/oauth2-proxy /usr/local/bin/

# Config
sudo mkdir -p /etc/oauth2-proxy
cat <<EOF | sudo tee /etc/oauth2-proxy/oauth2-proxy.cfg
provider = "github"
client_id = "YOUR_CLIENT_ID"
client_secret = "YOUR_CLIENT_SECRET"
cookie_secret = "RANDOM_32_BYTE_BASE64"
cookie_secure = false
email_domains = [ "*" ]
upstreams = [ "http://192.168.56.10:5601" ]
http_address = "0.0.0.0:4180"
redirect_url = "http://oauth.local/oauth2/callback"
EOF

# Systemd
cat <<EOF | sudo tee /etc/systemd/system/oauth2-proxy.service
[Unit]
Description=OAuth2 Proxy
After=network.target

[Service]
ExecStart=/usr/local/bin/oauth2-proxy --config=/etc/oauth2-proxy/oauth2-proxy.cfg
Restart=always
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable oauth2-proxy
sudo systemctl start oauth2-proxy

# Nginx config
cat <<'EOF' | sudo tee /etc/nginx/sites-available/kibana
server {
    listen 80;
    server_name oauth.local;

    location /oauth2/ {
        proxy_pass       http://127.0.0.1:4180;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Scheme $scheme;
    }

    location / {
        auth_request /oauth2/auth;
        error_page 401 = /oauth2/sign_in;

        proxy_pass       http://127.0.0.1:4180;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Scheme $scheme;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/kibana /etc/nginx/sites-enabled/
sudo systemctl restart nginx
