#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting user-data script execution..."

# Update package list
apt-get update

# Install nginx, docker, and ensure SSM Agent is installed
apt-get install -y nginx docker.io awscli curl

# Install and start SSM Agent (usually pre-installed on Ubuntu 22.04, but ensure it's running)
if ! systemctl is-active --quiet amazon-ssm-agent; then
    snap install amazon-ssm-agent --classic || true
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
fi

# Remove default nginx configuration
sudo rm -f /etc/nginx/sites-available/default

# Create new default.conf for reverse proxy (port 80 -> 8080)
sudo cat > /etc/nginx/sites-available/default << 'EOF'
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

# Create symbolic link to sites-enabled
ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Test nginx configuration
sudo nginx -t

# Start and enable nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Start and enable docker
sudo systemctl start docker
sudo systemctl enable docker

# Add ubuntu user to docker group (so they can run docker without sudo)
sudo usermod -aG docker ubuntu

echo "User-data script completed successfully!"
echo "Nginx configured to forward port 80 to 8080"
echo "Docker installed and ubuntu user added to docker group"
echo ""
echo "Note: You may need to log out and back in for docker group changes to take effect"
echo "Or run: newgrp docker"

# docker run -d --name app -p 8080:8080 --restart unless-stopped ${ecr_repository_url}:latest