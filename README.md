# Ideal Trips Limited — Assessment Part 1

This fork implements GET `/coupons_poc` in the existing `coupons` REST API.
The Node.js Lambda `coupons_list` returns HTTP 200 and exactly the static array in
`samples/t1_sample_coupons_list_response.json`. The historic sample dates are
preserved because this assessment requires the supplied response.

## Requirements

Docker Desktop with its engine running, authenticated LocalStack, Git/Git Bash,
Python (for ZIP packaging), AWS CLI, Node.js/npm. No external npm libraries are
needed by the static Lambda itself. Jest is installed for unit testing; Newman
is invoked through npm for API testing.

## Windows: run using Git Bash

Open Git Bash inside the cloned fork, not PowerShell. Start LocalStack first.
On a fresh LocalStack environment run:

```bash
bash scripts/run_part1.sh --bootstrap
```

This runs the instructor's bootstrap, unit tests, the three Part 1 provisioning
scripts, and Newman. The bootstrap initializes the infrastructure for later
assessment parts; those parts remain unimplemented. The original bootstrap is
not safe to rerun against an existing initialized environment. To repeat only
Part 1 after bootstrap has succeeded:

```bash
bash scripts/run_part1.sh
```

If bootstrap fails, keep its complete error output for diagnosis; do not blindly
rerun it against partially created resources. The bootstrap runtime was updated
from Node.js 14 to Node.js 22, and Lambda role arguments use full ARNs.

## Implementation

- `scripts/t1_provision_coupons_lambda_role.sh`: creates `coupons_lambda_role`
  and attaches the inline `coupons_lambda_policy`. Logging actions are restricted
  to `/aws/lambda/coupons*` log groups in local account `000000000000`, region
  `us-east-1`. DynamoDB actions are restricted to the `coupons` table. S3 is not
  included because the supplied Part 1 requirements specify only logs and DynamoDB.
- `scripts/t1_provision_coupons_list_lambda.sh`: packages `index.js` and
  `coupons.json` at the ZIP root, creates or updates the Lambda, and waits for it
  to become ready.
- `scripts/t1_provision_coupons_endpoint.sh`: finds the bootstrapped `coupons`
  API, adds `/coupons_poc`, configures public GET with `AWS_PROXY`, grants API
  Gateway permission to invoke this Lambda, and deploys the `local` stage.
- `lambda/coupons_list/tests/index.spec.js`: tests an API Gateway GET event,
  response status, JSON content type, exact sample response and repeat calls.
- `newman_tests/coupons_newman.json`: checks HTTP 200, content type and the exact
  three-coupon response over HTTP.

The script prints the endpoint and writes the base URL to `.coupons_base_url`
(which is ignored by Git). To rerun Newman separately:

```bash
npm exec --yes --package=newman -- newman run newman_tests/coupons_newman.json --env-var "baseUrl=$(cat .coupons_base_url)"
```

## Submission evidence

Capture the passing unit test and Newman output, the deployed endpoint response,
and the role policy. Useful commands from Git Bash:

```bash
source scripts/t1_common.sh
awslocal iam get-role --role-name coupons_lambda_role
awslocal iam get-role-policy --role-name coupons_lambda_role --policy-name coupons_lambda_policy
awslocal lambda get-function-configuration --function-name coupons_list
awslocal apigateway get-rest-apis
```

Commit and push to the fork's main branch after the local integration tests pass.
Submit the fork link to the instructor using the assessment naming instructions.
Keep authentication tokens out of source control.

## Validation status

Unit and collection validation performed in the development workspace are
reported separately from actual LocalStack deployment. LocalStack deployment
must be verified on the student's Docker environment; passing a local HTTP
contract check does not prove an AWS Gateway/Lambda deployment works.
