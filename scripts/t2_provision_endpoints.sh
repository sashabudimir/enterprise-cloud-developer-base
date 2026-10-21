#!/usr/bin/env bash
source "$(dirname "$0")/t2_common.sh"
API_ID="$(awslocal apigateway get-rest-apis --query 'items[?name==`coupons`].id | [0]' --output text)"
if [[ -z "$API_ID" || "$API_ID" == None ]]; then
  API_ID="$(awslocal apigateway create-rest-api --name coupons --query id --output text)"
fi
ROOT_ID="$(awslocal apigateway get-resources --rest-api-id "$API_ID" --query 'items[?path==`/`].id | [0]' --output text)"
COUPONS_ID="$(awslocal apigateway get-resources --rest-api-id "$API_ID" --query 'items[?path==`/coupons`].id | [0]' --output text)"
if [[ -z "$COUPONS_ID" || "$COUPONS_ID" == None ]]; then
  COUPONS_ID="$(awslocal apigateway create-resource --rest-api-id "$API_ID" --parent-id "$ROOT_ID" --path-part coupons --query id --output text)"
fi
RESOURCE_ID="$(awslocal apigateway get-resources --rest-api-id "$API_ID" --query 'items[?path==`/coupons/{id}`].id | [0]' --output text)"
if [[ -z "$RESOURCE_ID" || "$RESOURCE_ID" == None ]]; then
  RESOURCE_ID="$(awslocal apigateway create-resource --rest-api-id "$API_ID" --parent-id "$COUPONS_ID" --path-part '{id}' --query id --output text)"
fi
for METHOD in GET PUT; do
  if [[ "$METHOD" == GET ]]; then FUNCTION=coupons_get_by_id; else FUNCTION=coupons_update; fi
  if ! awslocal apigateway get-method --rest-api-id "$API_ID" --resource-id "$RESOURCE_ID" --http-method "$METHOD" >/dev/null 2>&1; then
    awslocal apigateway put-method --rest-api-id "$API_ID" --resource-id "$RESOURCE_ID" \
      --http-method "$METHOD" --authorization-type NONE \
      --request-parameters method.request.path.id=true >/dev/null
  fi
  LAMBDA_ARN="$(awslocal lambda get-function --function-name "$FUNCTION" --query Configuration.FunctionArn --output text)"
  awslocal apigateway put-integration --rest-api-id "$API_ID" --resource-id "$RESOURCE_ID" \
    --http-method "$METHOD" --type AWS_PROXY --integration-http-method POST \
    --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" >/dev/null
  SID="part2-${METHOD}-${API_ID}"
  POLICY="$(awslocal lambda get-policy --function-name "$FUNCTION" --query Policy --output text 2>/dev/null || true)"
  if [[ "$POLICY" != *"$SID"* ]]; then
    awslocal lambda add-permission --function-name "$FUNCTION" --statement-id "$SID" \
      --action lambda:InvokeFunction --principal apigateway.amazonaws.com \
      --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/${METHOD}/coupons/*" >/dev/null
  fi
done
awslocal apigateway create-deployment --rest-api-id "$API_ID" --stage-name "$STAGE" >/dev/null
BASE_URL="http://${API_ID}.execute-api.localhost.localstack.cloud:4566/${STAGE}"
printf '%s\n' "$BASE_URL" > .coupons_base_url
echo "GET and PUT ${BASE_URL}/coupons/{id}"
