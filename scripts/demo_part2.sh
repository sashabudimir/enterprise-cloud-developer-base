#!/usr/bin/env bash
source "$(dirname "$0")/t2_common.sh"
echo 'PROJECT 2: UNIT TESTS'
for FUNCTION in coupons_get_by_id coupons_update; do
  (cd "lambda/$FUNCTION" && npm ci --ignore-scripts && npm test -- --runInBand)
done
echo 'PROJECT 2: GET, PUT, PERSISTENCE AND ERROR RESPONSES'
npx --yes newman run newman_tests/coupons_part2_newman.json \
  --env-var "baseUrl=$(cat .coupons_base_url)"
echo 'PROJECT 2: TABLE CAPACITY AND ACTIVE INDEX'
awslocal dynamodb describe-table --table-name coupons \
  --query 'Table.{Name:TableName,Key:KeySchema,Capacity:ProvisionedThroughput,Indexes:GlobalSecondaryIndexes}'
echo 'PROJECT 2: QUERY THE PROVIDER/CAMPAIGN INDEX'
awslocal dynamodb query --table-name coupons --index-name provider_campaign_index \
  --key-condition-expression '#p = :p AND #c = :c' \
  --expression-attribute-names '{"#p":"provider_id","#c":"campaign_id"}' \
  --expression-attribute-values '{":p":{"S":"FAIRMONT"},":c":{"S":"CHRISTMAS2022"}}'
echo 'PROJECT 2: COUPON RETURNED BY THE DEPLOYED API'
curl --fail --silent --show-error \
  "$(cat .coupons_base_url)/coupons/319326de971100158f6fa0daeec978fba1f17e4b"
printf '\nOpen this URL in your browser: %s/coupons/319326de971100158f6fa0daeec978fba1f17e4b\n' "$(cat .coupons_base_url)"
