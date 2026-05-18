#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/odoo_pos"

JWT_SECRET="$(openssl rand -base64 48)"
FERNET="$(
  docker run --rm python:3.12-slim sh -c \
    "pip install -q cryptography >/dev/null 2>&1 && python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())'"
)"

umask 077
cat > deploy/.env.api <<EOF
ENV=production
CORS_ORIGINS=https://pos.myvnc.com,http://pos.myvnc.com
JWT_SECRET=${JWT_SECRET}
SECRETS_ENCRYPTION_KEY=${FERNET}
RESEND_API_KEY=
SMTP_FROM=no-reply@pos.local
CAPTCHA_PROVIDER=
CAPTCHA_SECRET=
EOF
chmod 600 deploy/.env.api

docker compose -f docker-compose.prod.yml up -d --build

echo "Waiting for API..."
for i in $(seq 1 60); do
  if docker exec pos_api_prod curl -sf "http://127.0.0.1:8000/health" >/dev/null 2>&1; then
    echo "API up."
    break
  fi
  sleep 2
done

docker exec pos_api_prod python -m app.scripts.seed || true

echo "Done shelf_server_setup.sh"
