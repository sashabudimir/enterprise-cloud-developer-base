#!/usr/bin/env bash
source "$(dirname "$0")/t1_common.sh"
if ! awslocal iam get-role --role-name coupons_lambda_role >/dev/null 2>&1; then
  awslocal iam create-role --role-name coupons_lambda_role \
    --assume-role-policy-document file://scripts/coupons_lambda_role_assume_role_policy.json
fi
awslocal iam put-role-policy --role-name coupons_lambda_role \
  --policy-name coupons_lambda_policy --policy-document file://scripts/coupons_lambda_policy.json
