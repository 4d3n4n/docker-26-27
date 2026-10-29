#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 IMAGE [--push REGISTRY_IMAGE]" >&2
  exit 2
}

[[ $# -eq 1 || ( $# -eq 3 && "$2" == '--push' ) ]] || usage
image="$1"
target="${3:-}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
signing_config="${script_dir}/../signing-config.json"

for tool in docker jq trivy syft; do
  command -v "${tool}" >/dev/null || { echo "Outil requis absent : ${tool}" >&2; exit 1; }
done
if [[ -n "${target}" ]]; then
  [[ "${target##*/}" == *:* ]] || { echo 'REGISTRY_IMAGE doit porter un tag explicite.' >&2; exit 2; }
  command -v cosign >/dev/null || { echo 'Outil requis absent : cosign' >&2; exit 1; }
  [[ -f "${COSIGN_KEY:-}" ]] || { echo 'Définissez COSIGN_KEY vers une clé privée Cosign.' >&2; exit 1; }
  jq -e '(.rekorTlogUrls == null or .rekorTlogUrls == []) and
         (.timestampAuthorities == null or .timestampAuthorities == []) and
         (.fulcio == null or .fulcio == []) and
         (.oidcProviders == null or .oidcProviders == [])' "${signing_config}" >/dev/null || {
    echo 'Configuration Cosign locale invalide : service externe déclaré.' >&2
    exit 1
  }
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

docker image inspect "${image}" > "${work_dir}/inspect.json"
for label in version revision source; do
  jq -e --arg key "org.opencontainers.image.${label}" \
    '.[0].Config.Labels[$key] | strings | select(length > 0)' \
    "${work_dir}/inspect.json" >/dev/null || {
      echo "Refus : label OCI ${label} absent ou vide" >&2
      exit 1
    }
done

user="$(jq -r '.[0].Config.User // ""' "${work_dir}/inspect.json")"
primary_user="${user%%:*}"
if [[ -z "${primary_user}" || "${primary_user}" == root || "${primary_user}" =~ ^0+$ ]]; then
  echo 'Refus : image exécutée en root' >&2
  exit 1
fi
jq -e '.[0].Config.Healthcheck.Test | arrays | length > 0 and .[0] != "NONE"' \
  "${work_dir}/inspect.json" >/dev/null || {
    echo 'Refus : HEALTHCHECK absent ou désactivé' >&2
    exit 1
  }

echo "Scan des CVE corrigeables HIGH/CRITICAL : ${image}"
trivy image --quiet --scanners vuln --severity HIGH,CRITICAL --ignore-unfixed \
  --format json --output "${work_dir}/vuln.json" "${image}"
vulnerabilities="$(jq '[.Results[]? | .Vulnerabilities[]?] | length' "${work_dir}/vuln.json")"
if (( vulnerabilities > 0 )); then
  echo "Refus : ${vulnerabilities} entrées HIGH/CRITICAL corrigeables (CVE × paquet)" >&2
  jq -r '.Results[]? | .Vulnerabilities[]? | "\(.VulnerabilityID) \(.PkgName) \(.InstalledVersion) -> \(.FixedVersion)"' \
    "${work_dir}/vuln.json" >&2
  exit 1
fi

echo "Scan des secrets : ${image}"
trivy image --quiet --scanners secret --format json --output "${work_dir}/secret.json" "${image}"
secrets="$(jq '[.Results[]? | .Secrets[]?] | length' "${work_dir}/secret.json")"
if (( secrets > 0 )); then
  echo "Refus : ${secrets} secret(s) détecté(s)" >&2
  jq -r '.Results[]? | .Secrets[]? | "\(.RuleID) \(.Target // "")"' \
    "${work_dir}/secret.json" >&2
  exit 1
fi

syft "${image}" -q -o spdx-json > "${work_dir}/sbom.spdx.json"
jq -e '.spdxVersion and (.packages | type == "array")' "${work_dir}/sbom.spdx.json" >/dev/null
if [[ -n "${SBOM_OUTPUT:-}" ]]; then
  cp "${work_dir}/sbom.spdx.json" "${SBOM_OUTPUT}"
fi

if [[ -z "${target}" ]]; then
  echo "Accepté : ${image} ; SBOM généré ($(jq '.packages | length' "${work_dir}/sbom.spdx.json") composants)."
  exit 0
fi

docker tag "${image}" "${target}"
docker push "${target}" | tee "${work_dir}/push.log"
digest="$(sed -nE 's/.*digest: (sha256:[0-9a-f]{64}).*/\1/p' "${work_dir}/push.log" | tail -n 1)"
[[ -n "${digest}" ]] || { echo 'Digest absent de la réponse du push' >&2; exit 1; }
reference="${target%:*}@${digest}"

cosign_args=()
if [[ -n "${REGISTRY_CA_FILE:-}" ]]; then
  cosign_args+=(--registry-cacert "${REGISTRY_CA_FILE}")
fi
export COSIGN_DOCKER_MEDIA_TYPES=1
cosign sign --yes --signing-config "${signing_config}" --key "${COSIGN_KEY}" \
  "${cosign_args[@]}" "${reference}"
cosign attest --yes --signing-config "${signing_config}" --key "${COSIGN_KEY}" \
  --type spdxjson --predicate "${work_dir}/sbom.spdx.json" \
  "${cosign_args[@]}" "${reference}"
echo "Publié, signé et attesté : ${reference}"
