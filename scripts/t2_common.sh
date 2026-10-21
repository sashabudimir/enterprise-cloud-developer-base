#!/usr/bin/env bash
# Run scripts with bash; do not source this file from an interactive terminal.
source "$(dirname "${BASH_SOURCE[0]}")/t1_common.sh"
export AWS_CLI_AUTO_PROMPT=off

deploy_part2_lambda() {
  local name="$1"
  local role_arn
  role_arn="$(awslocal iam get-role --role-name coupons_lambda_role --query Role.Arn --output text)"
  (cd "lambda/$name" && npm ci --omit=dev --ignore-scripts)
  # Package only runtime code and dependencies, with index.js at the ZIP root.
  python scripts/package_part2_lambda.py "$name"
  local environment='Variables={COUPONS_TABLE=coupons,DYNAMODB_ENDPOINT=http://localhost.localstack.cloud:4566}'
  if awslocal lambda get-function --function-name "$name" >/dev/null 2>&1; then
    awslocal lambda wait function-active-v2 --function-name "$name"
    awslocal lambda update-function-code --function-name "$name" --zip-file "fileb://${name}.zip" >/dev/null
    awslocal lambda wait function-updated-v2 --function-name "$name"
    awslocal lambda update-function-configuration --function-name "$name" \
      --runtime nodejs22.x --handler index.handler --role "$role_arn" \
      --timeout 15 --environment "$environment" >/dev/null
    awslocal lambda wait function-updated-v2 --function-name "$name"
  else
    awslocal lambda create-function --function-name "$name" \
      --runtime nodejs22.x --handler index.handler --role "$role_arn" \
      --timeout 15 --environment "$environment" --zip-file "fileb://${name}.zip" >/dev/null
    awslocal lambda wait function-active-v2 --function-name "$name"
  fi
  echo "$name deployed successfully"
}
