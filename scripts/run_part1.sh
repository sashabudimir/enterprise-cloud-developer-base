#!/usr/bin/env bash
source "$(dirname "$0")/t1_common.sh"
# PowerShell functions do not carry over into Git Bash; this file supplies awslocal.
# Python is already installed on the student's Windows computer.
zip() { (unset MSYS_NO_PATHCONV; python "$PROJECT_DIR/scripts/zip_directory.py" "$2" "$3"); }
export -f awslocal zip
if [[ "${1:-}" == "--resume-bootstrap" ]]; then
  export BOOTSTRAP_RESUME=1
  source scripts/t0_bootstrap_environment.sh
elif [[ "${1:-}" == "--bootstrap" ]]; then
  # Run once on a fresh LocalStack environment. The supplied bootstrap is not idempotent.
  source scripts/t0_bootstrap_environment.sh
fi
(cd lambda/coupons_list && npm ci --ignore-scripts && npm test -- --runInBand)
bash scripts/t1_provision_coupons_lambda_role.sh
bash scripts/t1_provision_coupons_list_lambda.sh
bash scripts/t1_provision_coupons_endpoint.sh
npx --yes newman run newman_tests/coupons_newman.json \
  --env-var "baseUrl=$(cat .coupons_base_url)"
