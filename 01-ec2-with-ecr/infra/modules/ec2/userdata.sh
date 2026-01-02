#!/bin/bash

# Log all output
exec > /var/log/user-data.log 2>&1

echo "========================================="
echo "Starting user-data script..."
echo "Date: $(date)"
echo "========================================="

export DEBIAN_FRONTEND=noninteractive

# IMPORTANT: Create nginx config BEFORE installing nginx
# This prevents nginx's post-install from creating default config issues
echo "[1/6] Creating nginx reverse proxy config (before nginx install)..."
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

cat > /etc/nginx/sites-available/reverse-proxy << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

echo "Config file created:"
cat /etc/nginx/sites-available/reverse-proxy

echo "[2/6] Updating packages..."
apt-get update

echo "[3/6] Installing nginx, docker, awscli, curl..."
apt-get install -y nginx docker.io awscli curl

echo "[4/6] Configuring nginx..."
# Remove default site from both sites-enabled AND sites-available
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default
ln -sf /etc/nginx/sites-available/reverse-proxy /etc/nginx/sites-enabled/reverse-proxy

echo "Sites available:"
ls -la /etc/nginx/sites-available/
echo "Sites enabled:"
ls -la /etc/nginx/sites-enabled/

echo "[5/6] Testing and restarting nginx..."
nginx -t
systemctl restart nginx
systemctl enable nginx

echo "[6/6] Setting up docker..."
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

echo "========================================="
echo "User-data completed successfully!"
echo "Date: $(date)"
echo "========================================="
