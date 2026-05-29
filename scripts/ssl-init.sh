#!/usr/bin/env bash
# Initialize TLS certificates for production nginx (./ssl/cert.pem + ./ssl/key.pem).
#
# Usage:
#   ./scripts/ssl-init.sh self-signed [common-name]     # dev / first boot
#   ./scripts/ssl-init.sh letsencrypt DOMAIN EMAIL      # public domain (HTTP-01)
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SSL_DIR="$ROOT/ssl"
LE_DIR="$ROOT/certbot/conf"
WEBROOT="$ROOT/certbot/www"
COMPOSE=(docker compose -f "$ROOT/docker-compose.prod.yml")

usage() {
  cat <<'EOF'
Usage:
  ./scripts/ssl-init.sh self-signed [common-name]
  ./scripts/ssl-init.sh letsencrypt DOMAIN EMAIL

Examples:
  ./scripts/ssl-init.sh self-signed localhost
  ./scripts/ssl-init.sh letsencrypt trafficlab.example.com admin@example.com

Certificates are written to:
  ssl/cert.pem
  ssl/key.pem
EOF
}

require_openssl() {
  if ! command -v openssl &>/dev/null; then
    echo "openssl is required but not installed." >&2
    exit 1
  fi
}

install_self_signed() {
  local cn="${1:-localhost}"
  require_openssl
  mkdir -p "$SSL_DIR"
  chmod 700 "$SSL_DIR"

  echo "Generating self-signed certificate (CN=$cn)..."
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$SSL_DIR/key.pem" \
    -out "$SSL_DIR/cert.pem" \
    -subj "/CN=$cn"
  chmod 600 "$SSL_DIR/key.pem" "$SSL_DIR/cert.pem"
  echo "Wrote $SSL_DIR/cert.pem and $SSL_DIR/key.pem"
  echo "Browsers will warn until you replace these with a trusted certificate."
}

copy_letsencrypt_certs() {
  local domain="$1"
  local live="$LE_DIR/live/$domain"

  if [[ ! -f "$live/fullchain.pem" || ! -f "$live/privkey.pem" ]]; then
    echo "Expected Let's Encrypt files under $live" >&2
    exit 1
  fi

  cp "$live/fullchain.pem" "$SSL_DIR/cert.pem"
  cp "$live/privkey.pem" "$SSL_DIR/key.pem"
  chmod 600 "$SSL_DIR/cert.pem" "$SSL_DIR/key.pem"
  echo "Installed $SSL_DIR/cert.pem and $SSL_DIR/key.pem from Let's Encrypt."
}

install_letsencrypt() {
  local domain="$1"
  local email="$2"

  mkdir -p "$SSL_DIR" "$LE_DIR" "$WEBROOT"
  chmod 700 "$SSL_DIR"

  if [[ ! -f "$SSL_DIR/cert.pem" || ! -f "$SSL_DIR/key.pem" ]]; then
    echo "No edge certificate yet; creating temporary self-signed cert so nginx can start..."
    install_self_signed "$domain"
  fi

  echo "Starting nginx for ACME HTTP-01 validation..."
  "${COMPOSE[@]}" up -d nginx

  echo "Requesting certificate from Let's Encrypt for $domain..."
  docker run --rm \
    -v "$LE_DIR:/etc/letsencrypt" \
    -v "$WEBROOT:/var/www/certbot" \
    certbot/certbot certonly --webroot \
    -w /var/www/certbot \
    -d "$domain" \
    --email "$email" \
    --agree-tos \
    --non-interactive \
    --keep-until-expiring

  copy_letsencrypt_certs "$domain"

  echo "Reloading nginx..."
  "${COMPOSE[@]}" exec -T nginx nginx -s reload
  echo "Done. HTTPS should now use a trusted certificate for $domain."
}

main() {
  local mode="${1:-}"
  shift || true

  case "$mode" in
    self-signed)
      install_self_signed "${1:-localhost}"
      ;;
    letsencrypt)
      if [[ $# -lt 2 ]]; then
        usage
        exit 1
      fi
      install_letsencrypt "$1" "$2"
      ;;
    -h|--help|help|"")
      usage
      exit 0
      ;;
    *)
      echo "Unknown mode: $mode" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
