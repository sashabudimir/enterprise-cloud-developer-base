# Coupons API – Project 2

I added a DynamoDB table to store coupons and updated the API to read and update them.

- GET /coupons/{id} returns a coupon using its ID.
- PUT /coupons/{id} updates an existing coupon.
- The table has an index using provider_id and campaign_id.

I tested the project using LocalStack. All 24 unit tests and 12 Newman checks passed.

The commands are in Command.txt. Test results and API output are in evidence/part2.

With Docker and LocalStack running, run:

```bash
bash scripts/run_part2.sh
```

To run the demonstration:

```bash
bash scripts/demo_part2.sh
```
