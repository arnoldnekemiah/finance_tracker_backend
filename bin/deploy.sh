#!/bin/bash -e

# Define health check function
check_service_health() {
    local service=$1
    local max_attempts=$2
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if sudo docker compose ps | grep -q "${service}.*healthy"; then
            return 0
        fi
        echo "Waiting for $service to be healthy... Attempt $attempt/$max_attempts"
        sleep 5
        attempt=$((attempt + 1))
    done
    return 1
}

# Load environment variables
if [ ! -f .env ]; then
    echo "Error: .env file not found!"
    exit 1
fi

source .env

# Install required packages
sudo apt-get update && sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    nginx \
    certbot \
    python3-certbot-nginx

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
fi

# Setup SSL (modify with your domain)
# sudo certbot --nginx -d yourdomain.com

# Backup database if containers are running
if docker compose ps | grep -q "db.*running"; then
    timestamp=$(date +%Y%m%d_%H%M%S)
    sudo docker compose exec db pg_dump -U $POSTGRES_USER $POSTGRES_DB > "backup_${timestamp}.sql"
fi

# Deploy main application
echo "Deploying main application..."
sudo docker compose down --remove-orphans
sudo docker compose build --no-cache

# Start the database first
sudo docker compose up -d db
sleep 5  # Give the database time to start

# Create the database if it doesn't exist
sudo docker compose exec -T db psql -U ${POSTGRES_USER} -c "CREATE DATABASE ${POSTGRES_DB};" || true

# Start the rest of the services
sudo docker compose up -d

# Wait for main application to be healthy
if ! check_service_health "app" 30; then
    echo "Application failed to start properly"
    sudo docker compose logs
    exit 1
fi

# Deploy monitoring stack
echo "Deploying monitoring stack..."
sudo docker compose -f docker-compose.monitoring.yml up -d

# Run migrations
sudo docker compose exec app rails db:migrate

# Create backup script
echo '#!/bin/bash
timestamp=$(date +%Y%m%d_%H%M%S)
docker compose exec db pg_dump -U $POSTGRES_USER $POSTGRES_DB > "/backups/backup_${timestamp}.sql"
find /backups -type f -mtime +7 -delete' > /usr/local/bin/backup-db.sh

# Make it executable
chmod +x /usr/local/bin/backup-db.sh

# Add to crontab
(crontab -l 2>/dev/null; echo "0 0 * * * /usr/local/bin/backup-db.sh") | crontab -

echo "Deployment completed successfully!"