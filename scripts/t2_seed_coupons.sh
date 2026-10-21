#!/usr/bin/env bash
source "$(dirname "$0")/t2_common.sh"
for ITEM in samples/t2_seed/*.json; do
  if RESULT="$(awslocal dynamodb put-item --table-name coupons --item "file://${ITEM}" \
    --condition-expression 'attribute_not_exists(coupon_id)' 2>&1)"; then
    echo "Inserted $ITEM"
  elif [[ "$RESULT" == *ConditionalCheckFailedException* ]]; then
    echo "Preserved existing coupon for $ITEM"
  else
    echo "$RESULT" >&2
    exit 1
  fi
done
