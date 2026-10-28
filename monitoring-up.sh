#!/usr/bin/env bash
set -euo pipefail

GRAFANA_PW="${1:?Usage: bash monitoring-up.sh <grafana-password>}"
cd "$(dirname "$0")"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null

helm upgrade --install kps prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  -f monitoring/prom-values.yaml \
  --set grafana.adminPassword="$GRAFANA_PW" \
  --wait --timeout 10m

kubectl get pods -n monitoring
echo "Grafana: kubectl port-forward -n monitoring svc/kps-grafana 3000:80 --address 0.0.0.0"
