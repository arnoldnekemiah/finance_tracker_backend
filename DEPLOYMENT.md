# Accountanta API — DigitalOcean Deployment Guide

Database is hosted on **Neon** (serverless PostgreSQL). The Droplet only runs the Rails app + Nginx. No local database container needed.

---

## Cost Estimate

| Item | Cost |
|------|------|
| DigitalOcean Droplet — Basic, 1GB RAM, 1 vCPU, 25GB SSD | **$6/mo** |
| Neon PostgreSQL (free tier) | **$0/mo** |
| SSL certificate (Let's Encrypt) | **Free** |
| Domain (optional — not needed to get started) | ~$1/mo |
| **Total without domain** | **$6/mo** |
| **Total with domain** | **$7/mo** |

> **Why not the $4 plan?** The 512MB RAM Droplet can OOM-kill Docker + Rails on startup. 1GB ($6) is the safe minimum.  
> Neon's free tier gives you 0.5 GB storage + 190 compute hours/month — enough for a small production app. Upgrade to Neon's $19/mo plan when you need more.

## Your API Base URL

DigitalOcean does not give you a hostname — your API is accessible via the raw Droplet IP:

```
http://<your-droplet-ip>
```

Examples:
```
http://167.99.12.34/api/v1/auth/login
http://167.99.12.34/api-docs        ← Swagger UI
```

When you add a domain later, it becomes `https://api.yourdomain.com` — everything else stays the same.

---

## Prerequisites

Before starting, have these ready:

- [ ] DigitalOcean account
- [ ] Neon project with the connection string (from your Neon dashboard)
- [ ] `config/master.key` content (never commit this file)
- [ ] `JWT_SECRET_KEY` — run locally: `openssl rand -hex 64`
- [ ] Google OAuth credentials (Client ID + Secret) if using Google login
- [ ] Gmail App Password for mailer
- [ ] A domain name pointed at the Droplet IP (or use the raw IP for testing)

---

## Step 1 — Create the Droplet

1. Log in to [DigitalOcean](https://cloud.digitalocean.com)
2. Click **Create → Droplets**
3. Choose:
   - **Region:** closest to your users (e.g. New York, London, Singapore)
   - **Image:** Ubuntu 24.04 LTS
   - **Size:** Basic — **Regular SSD — $6/mo (1GB / 1 vCPU / 25GB)**
   - **Authentication:** SSH Key (add your public key — `~/.ssh/id_rsa.pub`)
   - **Hostname:** `accountanta-api`
4. Click **Create Droplet** and note the IP address

---

## Step 2 — Note Your Droplet IP (Your API Base URL)

After the Droplet is created, DigitalOcean shows you its IP address on the dashboard.

That IP **is your API base URL**:

```
http://<your-droplet-ip>
```

Test it once the app is running:

```bash
curl http://<your-droplet-ip>/up
```

> **Adding a domain later:** Create an `A` record pointing `api.yourdomain.com` → your Droplet IP, update `server_name` in the Nginx config, then run `sudo certbot --nginx -d api.yourdomain.com` for free HTTPS.

---

## Step 3 — First-Time Server Setup

SSH into the Droplet as root:

```bash
ssh root@<droplet-ip>
```

Run the automated setup script (this takes ~5 minutes):

```bash
# On the Droplet:
curl -fsSL https://raw.githubusercontent.com/arnoldnekemiah/finance_tracker_backend/main/bin/setup_droplet.sh | bash
```

This script installs: Docker, Docker Compose, Nginx, Certbot, UFW firewall, fail2ban, and creates a `deploy` user.

> **If you prefer to run it manually**, copy `bin/setup_droplet.sh` to the server and run `bash setup_droplet.sh`.

When it finishes, **log out and reconnect as the deploy user**:

```bash
exit
ssh deploy@<droplet-ip>
```

---

## Step 4 — Clone the Repository

```bash
# On the Droplet, as the deploy user:
git clone https://github.com/arnoldnekemiah/finance_tracker_backend.git /home/deploy/app
cd /home/deploy/app
```

---

## Step 5 — Configure Environment Variables

```bash
cp .env.example .env
nano .env
```

Fill in every value. The critical ones:

```dotenv
RAILS_MASTER_KEY=<content of your local config/master.key>
DATABASE_URL=postgresql://USER:PASS@ep-xxxx.us-east-2.aws.neon.tech/neondb?sslmode=require
JWT_SECRET_KEY=<output of: openssl rand -hex 64>
APP_HOST=api.yourdomain.com
```

Get your `DATABASE_URL` from:  
**Neon Dashboard → Your Project → Connection Details → Select "Rails" from the dropdown**

Save and exit (`Ctrl+X`, then `Y`, then `Enter`).

---

## Step 6 — Configure Nginx

```bash
sudo cp nginx/accountanta.conf /etc/nginx/sites-available/accountanta
sudo ln -s /etc/nginx/sites-available/accountanta /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
```

The config already uses `server_name _;` which works with any IP — **no edits needed** for a raw IP setup.

Test and reload:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

---

## Step 7 — SSL Certificate (Skip for now — requires a domain)

You can skip this step entirely until you have a domain. Your API works fine over HTTP with the raw IP.

When you do add a domain:

```bash
# 1. Update server_name in the nginx config from _ to your domain
sudo nano /etc/nginx/sites-available/accountanta
# Change:  server_name _;
# To:      server_name api.yourdomain.com;

# 2. Get the cert
sudo certbot --nginx -d api.yourdomain.com

# 3. Verify auto-renewal
sudo certbot renew --dry-run
```

---

## Step 8 — Build and Launch the App

```bash
cd /home/deploy/app
bash bin/deploy.sh
```

This will:
1. Pull latest code from git
2. Build the Docker image
3. Run `rails db:migrate` against your Neon database
4. Start the container with `docker compose up -d`
5. Wait for the health check to pass
6. Reload Nginx

**First deploy takes 3–5 minutes** (building the Docker image). Subsequent deploys are ~30 seconds.

---

## Step 9 — Verify Everything Works

```bash
# Check container is running
docker ps

# Check app logs
docker logs accountanta_app --tail 50

# Test the health endpoint
curl http://localhost:3000/up

# Test through Nginx (use your actual Droplet IP)
curl http://<your-droplet-ip>/up
```

Expected response from `/up`: `200 OK`

---

## Deploying Future Updates

From your **local machine**:

```bash
git push origin main
```

Then SSH in and run:

```bash
ssh deploy@<droplet-ip>
cd /home/deploy/app
bash bin/deploy.sh
```

Or set up a GitHub Action to do this automatically (see below).

---

## Optional: GitHub Actions Auto-Deploy

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Droplet
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.DROPLET_IP }}
          username: deploy
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /home/deploy/app
            bash bin/deploy.sh
```

Add these secrets in GitHub → Settings → Secrets:
- `DROPLET_IP` — your Droplet's IP address
- `SSH_PRIVATE_KEY` — your local private key (`cat ~/.ssh/id_rsa`)

---

## Rollback

If a deploy breaks the app:

```bash
# On the Droplet:
cd /home/deploy/app
git log --oneline -5          # find the last good commit hash
git checkout <commit-hash>
SKIP_BUILD=0 bash bin/deploy.sh
```

---

## Monitoring

```bash
# Live container logs
docker logs accountanta_app -f

# Resource usage
docker stats accountanta_app

# Nginx access logs
sudo tail -f /var/log/nginx/accountanta_access.log

# Nginx error logs
sudo tail -f /var/log/nginx/accountanta_error.log
```

---

## Common Issues

| Problem | Fix |
|---------|-----|
| `OOMKilled` in `docker inspect` | Upgrade to $12/mo Droplet (2GB RAM) |
| `PG::ConnectionBad` | Check `DATABASE_URL` in `.env` — must include `?sslmode=require` for Neon |
| `ActiveStorage::FileNotFoundError` | The `rails_storage` Docker volume persists across deploys — don't delete it |
| Nginx 502 Bad Gateway | App not started yet — run `docker ps` and check logs |
| SSL cert fails | Ensure DNS A record is set and propagated before running Certbot |
| `Missing secret key base` | `RAILS_MASTER_KEY` in `.env` is wrong — must match `config/master.key` |

---

## File Reference

| File | Purpose |
|------|---------|
| `docker-compose.production.yml` | Defines the app container (no DB — using Neon) |
| `Dockerfile` | Builds the Rails app image |
| `nginx/accountanta.conf` | Nginx reverse proxy + SSL + rate limiting |
| `.env.example` | Template for all required environment variables |
| `bin/deploy.sh` | Run on Droplet to pull + build + restart the app |
| `bin/setup_droplet.sh` | Run once on a fresh Ubuntu 24.04 Droplet |
