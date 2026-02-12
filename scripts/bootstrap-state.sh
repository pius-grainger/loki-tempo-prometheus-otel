#!/usr/bin/env bash
#
# One-time script to create the S3 bucket and DynamoDB table
# used by Terraform for remote state management.
#
# Usage: ./bootstrap-state.sh [region]
#

set -euo pipefail

REGION="${1:-eu-west-2}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="${ACCOUNT_ID}-terraform-state"
DYNAMODB_TABLE="terraform-locks"

echo "==> AWS Account: ${ACCOUNT_ID}"

echo "==> Creating S3 bucket: ${BUCKET_NAME} in ${REGION}"
if aws s3api head-bucket --bucket "${BUCKET_NAME}" --region "${REGION}" 2>/dev/null; then
  echo "    Bucket already exists, skipping creation."
else
  aws s3api create-bucket \
    --bucket "${BUCKET_NAME}" \
    --region "${REGION}" \
    --create-bucket-configuration LocationConstraint="${REGION}"
fi

echo "==> Enabling versioning on ${BUCKET_NAME}"
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --region "${REGION}" \
  --versioning-configuration Status=Enabled

echo "==> Enabling encryption on ${BUCKET_NAME}"
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --region "${REGION}" \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "aws:kms"}, "BucketKeyEnabled": true}]
  }'

echo "==> Blocking public access on ${BUCKET_NAME}"
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --region "${REGION}" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "==> Creating DynamoDB table: ${DYNAMODB_TABLE} in ${REGION}"
if aws dynamodb describe-table --table-name "${DYNAMODB_TABLE}" --region "${REGION}" 2>/dev/null; then
  echo "    Table already exists, skipping creation."
else
  aws dynamodb create-table \
    --table-name "${DYNAMODB_TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}"
fi

echo "==> Done. Terraform state backend is ready."
echo ""
echo "Next steps:"
echo "  1. Uncomment the S3 backend block in environments/staging/backend.tf"
echo "  2. Set bucket = \"${BUCKET_NAME}\" in the backend block"
echo "  3. Run: cd environments/staging && terraform init -reconfigure"
