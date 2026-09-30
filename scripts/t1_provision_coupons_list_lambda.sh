#!/usr/bin/env bash
source "$(dirname "$0")/t1_common.sh"
# The static handler uses only built-in Node.js functionality: no runtime dependencies.
python -m zipfile -c coupons_list.zip lambda/coupons_list/index.js lambda/coupons_list/coupons.json
ROLE_ARN="$(awslocal iam get-role --role-name coupons_lambda_role --query Role.Arn --output text)"
if awslocal lambda get-function --function-name coupons_list >/dev/null 2>&1; then
  awslocal lambda update-function-code --function-name coupons_list --zip-file fileb://coupons_list.zip
  awslocal lambda wait function-updated-v2 --function-name coupons_list
  awslocal lambda update-function-configuration --function-name coupons_list \
    --runtime nodejs22.x --handler index.handler --role "$ROLE_ARN" --timeout 10
  awslocal lambda wait function-updated-v2 --function-name coupons_list
else
  awslocal lambda create-function --function-name coupons_list --runtime nodejs22.x \
    --handler index.handler --role "$ROLE_ARN" --timeout 10 --zip-file fileb://coupons_list.zip
  awslocal lambda wait function-active-v2 --function-name coupons_list
fi
