#!/usr/bin/env bash
# Accountanta API - Deployment script
# Run on the Droplet after setup_droplet.sh has been completed.
#
# Usage:
#   ./bin/deploy.sh               - deploy latest from git
#   SKIP_BUILD=1 ./bin/deploy.sh  - skip docker build (fast rollback)
set -euo pipefail

# Resolve app dir from the script's own location so it works wherever the repo is cloned
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE="docker compose -f docker-compose.production.yml"

# Force sequential Docker builds — faster on single-vCPU Droplets
export DOCKER_BUILDKIT=0
export COMPOSE_DOCKER_CLI_BUILD=0

echo "==> Pulling latest code..."
cd "$APP_DIR"
git pull origin main

if [ "${SKIP_BUILD:-0}" != "1" ]; then
  echo "==> Building Docker image..."
  docker build -t accountanta-api:latest .
fi

echo "==> Running database migrations..."
$COMPOSE run --rm app bundle exec rails db:migrate RAILS_ENV=production

echo "==> Restarting app container..."
$COMPOSE up -d --no-deps --remove-orphans app

echo "==> Waiting for health check..."
attempt=0
max=20
while true; do
  status=$(docker inspect --format='{{.State.Health.Status}}' accountanta_app 2>/dev/null || echo "missing")
  if [ "$status" = "healthy" ]; then
    break
  fi
  attempt=$((attempt + 1))
  if [ "$attempt" -ge "$max" ]; then
    echo "ERROR: App did not become healthy. Check logs:"
    $COMPOSE logs --tail=50 app
    exit 1
  fi
  echo "   Waiting... ($attempt/$max) — status: $status"
  sleep 5
done

echo "==> Reloading Nginx..."
sudo nginx -t && sudo systemctl reload nginx

echo ""
echo "Deployment complete."
echo "  Logs: docker compose -f docker-compose.production.yml logs -f app"