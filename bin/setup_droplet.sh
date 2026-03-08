#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Accountanta API — One-time Droplet provisioning script
#
# Run once on a fresh Ubuntu 24.04 LTS Droplet as root:
#   curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/finance_tracker_backend/main/bin/setup_droplet.sh | bash
#
# Or copy to the Droplet and run:
#   scp bin/setup_droplet.sh root@YOUR_DROPLET_IP:/tmp/
#   ssh root@YOUR_DROPLET_IP "bash /tmp/setup_droplet.sh"
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

APP_DIR="/opt/accountanta"
APP_USER="deploy"
GITHUB_REPO="https://github.com/arnoldnekemiah/finance_tracker_backend.git"

echo "======================================================"
echo " Accountanta — Droplet Setup"
echo "======================================================"

# ── 1. System packages ────────────────────────────────────────
echo "==> Updating packages..."
apt-get update -qq
apt-get upgrade -y -qq
apt-get install -y -qq \
  curl git nginx certbot python3-certbot-nginx \
  ufw fail2ban unattended-upgrades \
  ca-certificates gnupg lsb-release

# ── 2. Docker ─────────────────────────────────────────────────
echo "==> Installing Docker..."
if ! command -v docker &>/dev/null; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -qq
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  systemctl enable --now docker
fi

# ── 3. Deploy user ────────────────────────────────────────────
echo "==> Creating deploy user..."
if ! id "$APP_USER" &>/dev/null; then
  useradd -m -s /bin/bash "$APP_USER"
  usermod -aG docker "$APP_USER"
  usermod -aG sudo "$APP_USER"
  # Copy authorized SSH keys from root so you can connect as deploy
  mkdir -p /home/$APP_USER/.ssh
  cp /root/.ssh/authorized_keys /home/$APP_USER/.ssh/ 2>/dev/null || true
  chown -R $APP_USER:$APP_USER /home/$APP_USER/.ssh
  chmod 700 /home/$APP_USER/.ssh
  chmod 600 /home/$APP_USER/.ssh/authorized_keys 2>/dev/null || true
fi

# Allow deploy user to reload nginx without a password
echo "$APP_USER ALL=(ALL) NOPASSWD: /usr/bin/nginx, /bin/systemctl reload nginx, /bin/systemctl restart nginx" \
  > /etc/sudoers.d/deploy-nginx

# ── 4. Clone application ──────────────────────────────────────
echo "==> Cloning app to $APP_DIR..."
if [ ! -d "$APP_DIR/.git" ]; then
  git clone "$GITHUB_REPO" "$APP_DIR"
fi
chown -R $APP_USER:$APP_USER "$APP_DIR"

# ── 5. Environment file ───────────────────────────────────────
echo ""
echo "==> Creating .env..."
if [ ! -f "$APP_DIR/.env" ]; then
  cp "$APP_DIR/.env.example" "$APP_DIR/.env"
  chmod 600 "$APP_DIR/.env"
  chown $APP_USER:$APP_USER "$APP_DIR/.env"
  echo ""
  echo "  ┌───────────────────────────────────────────────────┐"
  echo "  │  ACTION REQUIRED: fill in $APP_DIR/.env          │"
  echo "  │  nano $APP_DIR/.env                               │"
  echo "  │  Then re-run: cd $APP_DIR && ./bin/deploy.sh      │"
  echo "  └───────────────────────────────────────────────────┘"
fi

# ── 6. Nginx ──────────────────────────────────────────────────
echo "==> Configuring Nginx..."
cp "$APP_DIR/nginx/accountanta.conf" /etc/nginx/sites-available/accountanta
ln -sf /etc/nginx/sites-available/accountanta /etc/nginx/sites-enabled/accountanta
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable --now nginx

# ── 7. Firewall ───────────────────────────────────────────────
echo "==> Setting up UFW firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 'Nginx Full'
ufw --force enable

# ── 8. Fail2ban ───────────────────────────────────────────────
echo "==> Enabling fail2ban..."
systemctl enable --now fail2ban

# ── 9. Automatic security updates ─────────────────────────────
echo "==> Enabling unattended security upgrades..."
echo 'Unattended-Upgrade::Automatic-Reboot "false";' \
  >> /etc/apt/apt.conf.d/50unattended-upgrades
dpkg-reconfigure -f noninteractive unattended-upgrades

echo ""
echo "======================================================"
echo " Droplet setup complete!"
echo "======================================================"
echo ""
echo " Next steps:"
echo " 1. Edit the .env file:  nano $APP_DIR/.env"
echo " 2. Point your domain's A record to this Droplet IP: $(curl -s ifconfig.me)"
echo " 3. Update api.yourdomain.com in nginx/accountanta.conf and .env"
echo " 4. Issue an SSL cert:"
echo "    certbot --nginx -d api.yourdomain.com --non-interactive --agree-tos -m you@example.com"
echo " 5. Deploy the app:"
echo "    su - $APP_USER -c 'cd $APP_DIR && ./bin/deploy.sh'"
echo ""
