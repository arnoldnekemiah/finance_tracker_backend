#!/bin/bash

# Exit on error
set -e

# Update package list and install essential packages
sudo apt-get update
sudo apt-get install -y docker.io docker-compose

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Install AWS CLI
sudo apt-get install -y awscli

# Pull the latest code (assuming you're using GitHub)
git pull origin main

# Build and start Docker containers
docker-compose build
docker-compose up -d

# Run database migrations
docker-compose exec app rails db:migrate 