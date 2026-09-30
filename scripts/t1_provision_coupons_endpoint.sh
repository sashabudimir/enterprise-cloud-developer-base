#!/usr/bin/env bash
source "$(dirname "$0")/t1_common.sh"
API_ID="$(awslocal apigateway get-rest-apis --query 'items[?name==`coupons`].id | [0]' --output text)"
if [[ -z "$API_ID" || "$API_ID" == None ]]; then
  echo "Missing coupons API. Run scripts/t0_bootstrap_environment.sh first." >&2
  exit 1
fi
ROOT_ID="$(awslocal apigateway get-resources --rest-api-id "$API_ID" --query 'items[?path==`/`].id | [0]' --output text)"
RESOURCE_ID="$(awslocal apigateway get-resources --rest-api-id "$API_ID" --query 'items[?path==`/coupons_poc`].id | [0]' --output text)"
if [[ -z "$RESOURCE_ID" || "$RESOURCE_ID" == None ]]; then
  RESOURCE_ID="$(awslocal apigateway create-resource --rest-api-id "$API_ID" --parent-id "$ROOT_ID" --path-part coupons_poc --query id --output text)"
fi
if ! awslocal apigateway get-method --rest-api-id "$API_ID" --resource-id "$RESOURCE_ID" --http-method GET >/dev/null 2>&1; then
  awslocal apigateway put-method --rest-api-id "$API_ID" --resource-id "$RESOURCE_ID" \
    --http-method GET --authorization-type NONE
fi
LAMBDA_ARN="$(awslocal lambda get-function --function-name coupons_list --query Configuration.FunctionArn --output text)"
awslocal apigateway put-integration --rest-api-id "$API_ID" --resource-id "$RESOURCE_ID" \
  --http-method GET --type AWS_PROXY --integration-http-method POST \
  --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations"
# A REST proxy integration invokes Lambda using POST even though the public method is GET.
SID="apigateway-coupons-poc-${API_ID}"
POLICY="$(awslocal lambda get-policy --function-name coupons_list --query Policy --output text 2>/dev/null || true)"
if [[ "$POLICY" != *"$SID"* ]]; then
  awslocal lambda add-permission --function-name coupons_list --statement-id "$SID" \
    --action lambda:InvokeFunction --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/GET/coupons_poc"
fi
awslocal apigateway create-deployment --rest-api-id "$API_ID" --stage-name "$STAGE"
BASE_URL="http://${API_ID}.execute-api.localhost.localstack.cloud:4566/${STAGE}"
printf '%s\n' "$BASE_URL" > .coupons_base_url
printf 'GET %s/coupons_poc\n' "$BASE_URL"
