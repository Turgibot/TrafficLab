#!/bin/bash

# SmartTransportation Lab - Deployment Script
# Usage: ./deploy.sh [production|development]

set -e

ENVIRONMENT=${1:-production}
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "🚀 Deploying SmartTransportation Lab in $ENVIRONMENT mode..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose v2 is not available (docker compose)."
    exit 1
fi

mkdir -p ssl logs certbot/www

if [ "$ENVIRONMENT" = "production" ]; then
    echo "🔧 Setting up production environment..."
    export NODE_ENV=production
    COMPOSE_FILE="docker-compose.prod.yml"
    ENV_FILE="${ENV_FILE:-.env}"

    if [ ! -f "$ENV_FILE" ]; then
        echo "⚠️  No $ENV_FILE found. Copy env.docker-prod.example to .env and set secrets before a real deploy."
    fi

    if [ ! -f ssl/cert.pem ] || [ ! -f ssl/key.pem ]; then
        echo "🔒 No TLS certificate in ./ssl — generating a self-signed cert for first boot..."
        echo "   For a public domain, run: ./scripts/ssl-init.sh letsencrypt YOUR_DOMAIN admin@example.com"
        ./scripts/ssl-init.sh self-signed localhost
    fi

    COMPOSE=(docker compose -f "$COMPOSE_FILE")
    if [ -f "$ENV_FILE" ]; then
        COMPOSE+=(--env-file "$ENV_FILE")
    fi
else
    echo "🔧 Setting up development environment..."
    export NODE_ENV=development
    COMPOSE_FILE="docker-compose.yml"
    COMPOSE=(docker compose -f "$COMPOSE_FILE")
fi

echo "🛑 Stopping existing containers..."
"${COMPOSE[@]}" down || true

echo "🏗️ Building and starting containers..."
"${COMPOSE[@]}" up --build -d

echo "⏳ Waiting for services to start..."
sleep 10

echo "🔍 Checking service health..."

if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ Backend is healthy"
else
    echo "❌ Backend health check failed"
    exit 1
fi

if [ "$ENVIRONMENT" = "production" ]; then
    if curl -fk https://localhost/health > /dev/null 2>&1; then
        echo "✅ HTTPS edge (nginx) is healthy"
    else
        echo "❌ HTTPS health check failed (check nginx logs and ssl/cert.pem)"
        exit 1
    fi

    echo ""
    echo "🎉 Production deployment completed successfully!"
    echo ""
    echo "📊 Service URLs:"
    echo "   Site:     https://localhost/  (use your domain or -k for self-signed)"
    echo "   Health:   https://localhost/health"
    echo "   API Docs: https://localhost/docs"
    echo "   Backend:  http://127.0.0.1:8000 (loopback only)"
else
    if curl -f http://localhost:3000 > /dev/null 2>&1; then
        echo "✅ Frontend is healthy"
    else
        echo "❌ Frontend health check failed"
        exit 1
    fi

    echo ""
    echo "🎉 Development deployment completed successfully!"
    echo ""
    echo "📊 Service URLs:"
    echo "   Frontend: http://localhost:3000"
    echo "   Backend:  http://localhost:8000"
    echo "   API Docs: http://localhost:8000/docs"
fi

echo ""
echo "📝 Useful commands:"
echo "   View logs:     docker compose -f $COMPOSE_FILE logs -f"
echo "   Stop services: docker compose -f $COMPOSE_FILE down"
echo "   Restart:       docker compose -f $COMPOSE_FILE restart"
if [ "$ENVIRONMENT" = "production" ]; then
    echo "   Trusted TLS:   ./scripts/ssl-init.sh letsencrypt YOUR_DOMAIN admin@example.com"
    echo "   Renew TLS:     ./scripts/ssl-renew.sh"
fi
echo ""
