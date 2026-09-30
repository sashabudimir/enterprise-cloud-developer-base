#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
export AWS_PAGER="" MSYS_NO_PATHCONV=1
REGION=us-east-1
ACCOUNT_ID=000000000000
STAGE=local
# Use the working AWS CLI directly, including on Windows.
awslocal() { aws --endpoint-url=http://localhost:4566 --region "$REGION" "$@"; }
