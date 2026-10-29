#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/registry/registry-lib.sh"
registry_require_tools

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 REPO N [--apply]" >&2
  exit 2
fi
repo="$1"
keep="$2"
apply="${3:-}"
registry_validate_repo "${repo}"
[[ "${keep}" =~ ^[0-9]+$ ]] || registry_die "N doit être un entier positif ou zéro"
[[ -z "${apply}" || "${apply}" == '--apply' ]] || registry_die "option inconnue : ${apply}"

work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT
: > "${work_dir}/semver"
: > "${work_dir}/system"
: > "${work_dir}/nonsemver"
: > "${work_dir}/protected"

while IFS= read -r tag; do
  [[ -n "${tag}" ]] || continue
  registry_validate_tag "${tag}"
  digest="$(registry_manifest_digest "${repo}" "${tag}")"
  if [[ "${tag}" =~ ^sha256-[0-9a-f]{64}(\.(sig|att|sbom))?$ ]]; then
    printf '%s\n' "${digest}" >> "${work_dir}/protected"
    printf '%s\n' "${tag}" >> "${work_dir}/system"
    continue
  fi
  if [[ "${tag}" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]; then
    printf '%s\n' "${digest}" >> "${work_dir}/protected"
    printf '%s\n' "${tag}" >> "${work_dir}/semver"
    continue
  fi
  created="$(registry_tag_created "${repo}" "${tag}" || true)"
  if [[ -z "${created}" ]]; then
    echo "Date inconnue pour ${tag} : conservation par sécurité" >&2
    printf '%s\n' "${digest}" >> "${work_dir}/protected"
    continue
  fi
  printf '%s\t%s\t%s\n' "${tag}" "${created}" "${digest}" >> "${work_dir}/nonsemver"
done < <(registry_list_tags "${repo}")

LC_ALL=C sort -t $'\t' -k2,2r "${work_dir}/nonsemver" > "${work_dir}/sorted"
awk -F '\t' -v n="${keep}" 'NR <= n {print $3}' "${work_dir}/sorted" >> "${work_dir}/protected"
awk -F '\t' -v n="${keep}" 'NR > n {print $3}' "${work_dir}/sorted" | sort -u > "${work_dir}/candidates"

echo "Tags semver conservés : $(paste -sd ',' "${work_dir}/semver")"
echo "Tags Cosign conservés : $(paste -sd ',' "${work_dir}/system")"
echo "Tags non-semver récents conservés :"
awk -F '\t' -v n="${keep}" 'NR <= n {print $1}' "${work_dir}/sorted"

while IFS= read -r digest; do
  [[ -n "${digest}" ]] || continue
  tags="$(awk -F '\t' -v d="${digest}" '$3==d {printf "%s ", $1}' "${work_dir}/nonsemver")"
  if grep -Fxq "${digest}" "${work_dir}/protected"; then
    echo "Conservé : ${tags}(digest partagé avec un tag protégé)"
    continue
  fi
  if [[ "${apply}" == '--apply' ]]; then
    registry_curl --request DELETE --output /dev/null \
      "${registry_base}/v2/${repo}/manifests/${digest}"
    echo "Supprimé : ${tags}(${digest})"
  else
    echo "À supprimer : ${tags}(${digest})"
  fi
done < "${work_dir}/candidates"

if [[ "${apply}" == '--apply' ]]; then
  echo "Exécutez ensuite registry-api.sh gc en fenêtre de maintenance."
fi
