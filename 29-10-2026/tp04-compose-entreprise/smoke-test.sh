#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${script_dir}"

for tool in curl jq docker; do
  command -v "${tool}" >/dev/null || { echo "Outil manquant : ${tool}" >&2; exit 1; }
done

port="${SMOKE_PORT:-80}"
base="http://api.localhost:${port}"
curl_args=(--silent --show-error --fail --max-time 10 --resolve "api.localhost:${port}:127.0.0.1")
work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

curl "${curl_args[@]}" "${base}/ready" > "${work_dir}/ready.json"
jq -e '.status == "ready" and .checks.db == "ok" and .checks.redis == "ok"' \
  "${work_dir}/ready.json" >/dev/null

curl "${curl_args[@]}" "${base}/products" > "${work_dir}/products.json"
jq -e 'type == "array" and length >= 3' "${work_dir}/products.json" >/dev/null
curl "${curl_args[@]}" --dump-header "${work_dir}/headers" \
  "${base}/products" > /dev/null
grep -qi '^X-Cache: HIT' "${work_dir}/headers" || {
  echo 'Cache Redis non utilisé pour /products' >&2
  exit 1
}

curl "${curl_args[@]}" --request POST --header 'Content-Type: application/json' \
  --data '{"productId":1,"quantity":1}' "${base}/orders" > "${work_dir}/order.json"
jq -e '.status == "pending" and .productId == 1' "${work_dir}/order.json" >/dev/null

query='SELECT status FROM orders WHERE product_id = 1 ORDER BY id DESC LIMIT 1'
for attempt in {1..20}; do
  status="$(docker compose -f compose.yml exec -T db sh -ec \
    'export PGPASSWORD="$(cat /run/secrets/db_password)"; exec psql -h 127.0.0.1 -U shop -d shop -At -c "$1"' \
    sh "${query}" | tr -d '\r\n')"
  if [[ "${status}" == confirmed ]]; then
    echo 'OK : /ready, /products (cache HIT), commande confirmée par le worker.'
    exit 0
  fi
  sleep 1
done

echo "Commande non confirmée après 20 s (statut : ${status:-absent})." >&2
exit 1
