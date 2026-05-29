#!/usr/bin/env bash
# Renew Let's Encrypt certificates and reload nginx.
# Schedule monthly, e.g. cron: 0 3 1 * * /path/to/TrafficLab/scripts/ssl-renew.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SSL_DIR="$ROOT/ssl"
LE_DIR="$ROOT/certbot/conf"
WEBROOT="$ROOT/certbot/www"
COMPOSE=(docker compose -f "$ROOT/docker-compose.prod.yml")

if [[ ! -d "$LE_DIR/live" ]]; then
  echo "No Let's Encrypt data in $LE_DIR; nothing to renew." >&2
  exit 0
fi

domain="$(basename "$(ls -1 "$LE_DIR/live" | grep -v '^README$' | head -1)")"
if [[ -z "$domain" ]]; then
  echo "Could not determine certificate domain under $LE_DIR/live" >&2
  exit 1
fi

echo "Renewing certificate for $domain..."
docker run --rm \
  -v "$LE_DIR:/etc/letsencrypt" \
  -v "$WEBROOT:/var/www/certbot" \
  certbot/certbot renew --webroot -w /var/www/certbot

cp "$LE_DIR/live/$domain/fullchain.pem" "$SSL_DIR/cert.pem"
cp "$LE_DIR/live/$domain/privkey.pem" "$SSL_DIR/key.pem"
chmod 600 "$SSL_DIR/cert.pem" "$SSL_DIR/key.pem"

echo "Reloading nginx..."
"${COMPOSE[@]}" exec -T nginx nginx -s reload
echo "Renewal complete."
