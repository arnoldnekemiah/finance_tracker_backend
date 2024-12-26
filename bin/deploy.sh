#!/bin/bash -e

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

# Backup database
timestamp=$(date +%Y%m%d_%H%M%S)
sudo docker compose exec db pg_dump -U $POSTGRES_USER $POSTGRES_DB > "backup_${timestamp}.sql"

# Deploy application
sudo docker compose down
sudo docker system prune -af
sudo docker compose build --no-cache
sudo docker compose up -d

# Health check
echo "Performing health check..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl -f http://localhost:3001/health > /dev/null 2>&1; then
        echo "Application is healthy!"
        break
    fi
    echo "Waiting for application (attempt $attempt/$max_attempts)..."
    sleep 5
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    echo "Application failed to start properly"
    sudo docker compose logs
    exit 1
fi

# Run migrations
sudo docker compose exec app rails db:migrate

# Install Prometheus and Grafana
docker run -d \
    --name prometheus \
    -p 9090:9090 \
    prom/prometheus

docker run -d \
    --name grafana \
    -p 3000:3000 \
    grafana/grafana

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