#!/bin/bash

# Set backup directory
BACKUP_DIR="/home/ubuntu/backups"
mkdir -p $BACKUP_DIR

# Load environment variables
source .env

# Create backup with timestamp
timestamp=$(date +%Y%m%d_%H%M%S)
backup_file="${BACKUP_DIR}/backup_${timestamp}.sql"

# Perform backup
docker compose exec -T db pg_dump -U $POSTGRES_USER $POSTGRES_DB > "$backup_file"

# Compress backup
gzip "$backup_file"

# Delete backups older than 7 days
find $BACKUP_DIR -type f -name "*.sql.gz" -mtime +7 -delete

# Optional: Upload to S3 or other storage
# aws s3 cp "${backup_file}.gz" "s3://your-bucket/backups/"
