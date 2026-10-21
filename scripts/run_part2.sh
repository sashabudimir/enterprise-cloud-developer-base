#!/usr/bin/env bash
source "$(dirname "$0")/t2_common.sh"
echo 'Checking LocalStack (Docker and LocalStack must already be running)'
if ! awslocal dynamodb list-tables >/dev/null; then
  echo 'Start Docker Desktop and LocalStack, then rerun this command.' >&2
  exit 1
fi
mkdir -p evidence/part2
for FUNCTION in coupons_get_by_id coupons_update; do
  (cd "lambda/$FUNCTION" && npm ci --ignore-scripts && npm test -- \
    --runInBand --json --outputFile="../../evidence/part2/${FUNCTION}-unit-tests.json")
done
bash scripts/t1_provision_coupons_lambda_role.sh
bash scripts/t2_create_dynamodb_table.sh
bash scripts/t2_add_index_to_dynamodb_table.sh
bash scripts/t2_seed_coupons.sh
bash scripts/t2_update_coupons_get_by_id_lambda.sh
bash scripts/t2_update_coupons_update_lambda.sh
bash scripts/t2_provision_endpoints.sh
npx --yes newman run newman_tests/coupons_part2_newman.json \
  --env-var "baseUrl=$(cat .coupons_base_url)" --reporters cli,json \
  --reporter-json-export evidence/part2/newman-results.json
python scripts/capture_part2_evidence.py
echo 'Part 2 complete. Actual output and test results are in evidence/part2.'
