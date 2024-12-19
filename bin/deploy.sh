#!/bin/bash

# Exit on error and enable debug mode
set -eo pipefail

# Function for cleanup
cleanup() {
    echo "Cleaning up Docker resources..."
    sudo docker system prune -f
    sudo rm -f /var/lib/apt/lists/lock
    sudo rm -f /var/cache/apt/archives/lock
    sudo rm -f /var/lib/dpkg/lock*
}

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
    },
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}' | sudo tee /etc/docker/daemon.json

# Restart Docker daemon
sudo systemctl restart docker

# Enable the site and remove default
sudo ln -sf /etc/nginx/sites-available/finance_tracker /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test and restart Nginx
sudo nginx -t
sudo systemctl restart nginx

# Improved Docker build and deploy process
cleanup
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

echo "Building Docker containers..."
if ! sudo docker compose build --no-cache --parallel; then
    echo "Initial build failed, retrying after cleanup..."
    cleanup
    sudo docker compose build --no-cache --parallel
fi

echo "Starting containers..."
sudo docker compose up -d

# Health check
echo "Performing health check..."
max_attempts=30
attempt=1
while [ $attempt -le $max_attempts ]; do
    if curl -s http://localhost:3001/health > /dev/null; then
        echo "Application is healthy!"
        break
    fi
    echo "Waiting for application to be ready (attempt $attempt/$max_attempts)..."
    sleep 5
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    echo "Application failed to start properly"
    sudo docker compose logs
    exit 1
fi

# Run migrations
echo "Running database migrations..."
sudo docker compose exec -T app rails db:migrate || {
    echo "Migration failed!"
    sudo docker compose logs
    exit 1
}

echo "Deployment completed successfully!"