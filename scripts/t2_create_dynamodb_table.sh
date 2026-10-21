#!/usr/bin/env bash
source "$(dirname "$0")/t2_common.sh"
# A 1 KB item uses 0.5 RCU per eventual read and 1 WCU per write.
# 50 reads/second => 25 RCU; 10 writes/second => 10 WCU.
if awslocal dynamodb describe-table --table-name coupons >/dev/null 2>&1; then
  echo "coupons table already exists; preserving its items"
  CURRENT="$(awslocal dynamodb describe-table --table-name coupons \
    --query 'Table.ProvisionedThroughput.[ReadCapacityUnits,WriteCapacityUnits]' --output text)"
  read -r READ_UNITS WRITE_UNITS <<< "$CURRENT"
  if [[ "$READ_UNITS" != 25 || "$WRITE_UNITS" != 10 ]]; then
    awslocal dynamodb update-table --table-name coupons --billing-mode PROVISIONED \
      --provisioned-throughput ReadCapacityUnits=25,WriteCapacityUnits=10 >/dev/null
  fi
else
  awslocal dynamodb create-table --table-name coupons \
    --attribute-definitions AttributeName=coupon_id,AttributeType=S \
    --key-schema AttributeName=coupon_id,KeyType=HASH \
    --billing-mode PROVISIONED \
    --provisioned-throughput ReadCapacityUnits=25,WriteCapacityUnits=10 >/dev/null
fi
awslocal dynamodb wait table-exists --table-name coupons
awslocal dynamodb describe-table --table-name coupons \
  --query 'Table.{Name:TableName,Key:KeySchema,Capacity:ProvisionedThroughput}'

