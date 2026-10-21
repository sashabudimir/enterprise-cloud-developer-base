"""Capture actual LocalStack output; fail if the expected behavior is missing."""
import json
import subprocess
import time
from pathlib import Path
from urllib.request import Request, urlopen

root = Path(__file__).resolve().parent.parent
output = root / "evidence" / "part2"
output.mkdir(parents=True, exist_ok=True)
base_url = (root / ".coupons_base_url").read_text().strip()
sample = json.loads((root / "samples/t2_coupons_get_by_id_response.json").read_text())
coupon_id = sample["coupon_id"]


def save(name, data):
    (output / name).write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def aws(*args):
    result = subprocess.run([
        "aws", "--endpoint-url=http://localhost:4566", "--region", "us-east-1",
        *args, "--output", "json", "--no-cli-pager"
    ], check=True, capture_output=True, text=True)
    return json.loads(result.stdout)


def request(method, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = Request(f"{base_url}/coupons/{coupon_id}", data=data,
                  headers={"Content-Type": "application/json"}, method=method)
    with urlopen(req, timeout=30) as response:
        assert response.status == 200
        return json.load(response)


save("table-and-index.json", aws("dynamodb", "describe-table", "--table-name", "coupons"))
for name in ("coupons_get_by_id", "coupons_update"):
    save(f"{name}-configuration.json", aws(
        "lambda", "get-function-configuration", "--function-name", name))
save("role-policy.json", aws("iam", "get-role-policy", "--role-name",
                             "coupons_lambda_role", "--policy-name", "coupons_lambda_policy"))
query = aws("dynamodb", "query", "--table-name", "coupons", "--index-name",
            "provider_campaign_index", "--key-condition-expression", "#p = :p AND #c = :c",
            "--expression-attribute-names", '{"#p":"provider_id","#c":"campaign_id"}',
            "--expression-attribute-values", json.dumps({
                ":p": {"S": sample["provider_id"]}, ":c": {"S": sample["campaign_id"]}
            }))
save("index-query.json", query)
before = request("GET")
save("api-get-before.json", before)
try:
    updated = request("PUT", {"title": "Part 2 verified database update"})
    assert updated["title"] == "Part 2 verified database update"
    save("api-update.json", updated)
    for attempt in range(20):
        after = request("GET")
        if after.get("title") == updated["title"]:
            break
        time.sleep(1)
    assert after["title"] == updated["title"], "Update was not persisted"
    save("api-get-after.json", after)
finally:
    request("PUT", before)
save("endpoint.json", {"baseUrl": base_url, "get": f"{base_url}/coupons/{coupon_id}",
                       "put": f"{base_url}/coupons/{coupon_id}"})
print("Saved real table, index, Lambda, GET and PUT output to evidence/part2")
