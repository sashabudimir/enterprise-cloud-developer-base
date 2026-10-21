#!/usr/bin/env bash
source "$(dirname "$0")/t2_common.sh"
INDEX_NAME=provider_campaign_index
COUNT="$(awslocal dynamodb describe-table --table-name coupons \
  --query "length(Table.GlobalSecondaryIndexes[?IndexName=='${INDEX_NAME}'] || \`[]\`)" --output text)"
if [[ "$COUNT" == 0 ]]; then
  awslocal dynamodb update-table --table-name coupons \
    --attribute-definitions AttributeName=provider_id,AttributeType=S AttributeName=campaign_id,AttributeType=S \
    --global-secondary-index-updates ' [{"Create":{"IndexName":"provider_campaign_index","KeySchema":[{"AttributeName":"provider_id","KeyType":"HASH"},{"AttributeName":"campaign_id","KeyType":"RANGE"}],"Projection":{"ProjectionType":"ALL"},"ProvisionedThroughput":{"ReadCapacityUnits":25,"WriteCapacityUnits":10}}}]' >/dev/null
fi
# table-exists alone does not guarantee that a newly created GSI is active.
ACTIVE=0
for attempt in {1..60}; do
  STATUS="$(awslocal dynamodb describe-table --table-name coupons \
    --query "Table.GlobalSecondaryIndexes[?IndexName=='${INDEX_NAME}'].IndexStatus | [0]" --output text)"
  if [[ "$STATUS" == ACTIVE ]]; then ACTIVE=1; break; fi
  sleep 2
done
if [[ "$ACTIVE" != 1 ]]; then echo 'Index did not become ACTIVE' >&2; exit 1; fi
awslocal dynamodb describe-table --table-name coupons --query Table.GlobalSecondaryIndexes

