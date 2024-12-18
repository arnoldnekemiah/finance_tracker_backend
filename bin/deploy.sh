#!/bin/bash

# Exit on error
set -e

# Update system packages
sudo apt-get update
sudo apt-get upgrade -y

# Install required packages
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    nginx

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Configure Docker daemon for BuildKit
echo '{
  "features": {
    "buildkit": true
  }
}' | sudo tee /etc/docker/daemon.json

# Restart Docker daemon
sudo systemctl restart docker

# Set up Nginx configuration
sudo tee /etc/nginx/sites-available/finance_tracker << EOF
upstream rails_app {
    server 127.0.0.1:3001;
}

server {
    listen 80;
    server_name ec2-54-160-201-25.compute-1.amazonaws.com 54.160.201.25;

    location / {
        proxy_pass http://rails_app;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range';
    }
}
EOF

# Enable the site and remove default
sudo ln -sf /etc/nginx/sites-available/finance_tracker /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test and restart Nginx
sudo nginx -t
sudo systemctl restart nginx

# Clean up any existing Docker resources and locks before building
sudo rm -f /var/lib/apt/lists/lock
sudo rm -f /var/cache/apt/archives/lock
sudo rm -f /var/lib/dpkg/lock*
sudo docker compose down

# Build and start Docker containers with error handling
export DOCKER_BUILDKIT=1
if ! sudo docker compose build --no-cache --parallel; then
    echo "Docker build failed, retrying after cleanup..."
    sudo docker system prune -f
    sudo docker compose build --no-cache --parallel
fi
sudo docker compose up -d

# Wait for the application to be ready
echo "Waiting for the application to start..."
sleep 10

# Run database migrations
sudo docker compose exec app rails db:migrate

echo "Deployment completed successfully!"