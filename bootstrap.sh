#!/usr/bin/env bash

set -euo pipefail

# Usage: ./deploy.sh <DB_PASSWORD>

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <DB_PASSWORD>"
  exit 1
fi

# Resolve paths relative to this script
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

NAMESPACE="jerney"
DB_PASSWORD="$1"

echo "==> Creating namespace..."
kubectl create namespace "$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "==> Creating database secret..."
kubectl create secret generic jerney-db-secret \
  -n "$NAMESPACE" \
  --from-literal=DB_USER=jerney_user \
  --from-literal=DB_PASSWORD="$DB_PASSWORD" \
  --from-literal=DB_NAME=jerney_db \
  --dry-run=client -o yaml | kubectl apply -f -

unset DB_PASSWORD

echo "==> Deploying PostgreSQL..."
kubectl apply -f k8s/postgres.yaml

echo "==> Waiting for PostgreSQL StatefulSet..."
kubectl rollout status statefulset/postgres \
  -n "$NAMESPACE" --timeout=180s

echo "==> Deploying backend and frontend... and pdb"
kubectl apply -f k8s/backend.yaml -f k8s/frontend.yaml -f k8s/pdb.yaml

echo "==> Waiting for backend deployment..."
kubectl rollout status deployment/jerney-backend \
  -n "$NAMESPACE" --timeout=180s

echo "==> Waiting for frontend deployment..."
kubectl rollout status deployment/jerney-frontend \
  -n "$NAMESPACE" --timeout=180s

echo "==> Final deployment status..."
kubectl get pods,pvc -n "$NAMESPACE"

echo "==> Deployment completed successfully!"
