#!/usr/bin/env bash
#
# Build the sample-app-ts Docker image, push to ECR, and deploy to EKS.
#
# Usage:
#   ./deploy.sh                        # Uses defaults
#   ./deploy.sh --region eu-west-2     # Override region
#   ./deploy.sh --skip-build           # Skip Docker build, just apply k8s manifests
#
set -euo pipefail

REGION="${AWS_REGION:-eu-west-2}"
IMAGE_NAME="sample-app-ts"
IMAGE_TAG="latest"
SKIP_BUILD=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --region) REGION="$2"; shift 2 ;;
    --skip-build) SKIP_BUILD=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${IMAGE_NAME}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Step 1: Create ECR repository (if it doesn't exist) ──────────────
echo "==> Ensuring ECR repository exists: ${IMAGE_NAME}"
aws ecr describe-repositories --repository-names "${IMAGE_NAME}" --region "${REGION}" 2>/dev/null || \
  aws ecr create-repository --repository-name "${IMAGE_NAME}" --region "${REGION}" --image-scanning-configuration scanOnPush=true

# ── Step 2: Build & push Docker image ────────────────────────────────
if [ "$SKIP_BUILD" = false ]; then
  echo "==> Logging in to ECR"
  aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

  echo "==> Building Docker image: ${ECR_REPO}:${IMAGE_TAG}"
  docker build --platform linux/amd64 -t "${IMAGE_NAME}:${IMAGE_TAG}" .
  docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${ECR_REPO}:${IMAGE_TAG}"

  echo "==> Pushing image to ECR"
  docker push "${ECR_REPO}:${IMAGE_TAG}"
else
  echo "==> Skipping Docker build"
fi

# ── Step 3: Update deployment image and apply k8s manifests ──────────
echo "==> Updating deployment image to ${ECR_REPO}:${IMAGE_TAG}"
sed "s|image: sample-app-ts:latest|image: ${ECR_REPO}:${IMAGE_TAG}|" k8s/deployment.yaml | kubectl apply -f -

echo "==> Applying Service"
kubectl apply -f k8s/service.yaml

echo "==> Applying load generator CronJob"
kubectl apply -f k8s/loadgen-cronjob.yaml

# ── Step 4: Wait for rollout ─────────────────────────────────────────
echo "==> Waiting for deployment rollout..."
kubectl rollout status deployment/sample-app-ts -n observability --timeout=120s

echo ""
echo "==> Done! TypeScript sample app deployed."
echo ""
echo "Verify:"
echo "  kubectl get pods -n observability -l app=sample-app-ts"
echo "  kubectl logs -n observability -l app=sample-app-ts --tail=20"
echo ""
echo "Port-forward to test locally:"
echo "  kubectl port-forward svc/sample-app-ts 8081:80 -n observability"
echo "  curl http://localhost:8081/api/products"
echo "  curl -X POST http://localhost:8081/api/checkout"
echo ""
echo "The load generator CronJob runs every minute, hitting all endpoints."
echo "Check Grafana dashboards after 2-3 minutes to see data flowing."
