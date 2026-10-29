#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/registry/registry-lib.sh"
registry_require_tools

usage() {
  echo "Usage: $0 catalog | tags REPO | digest REPO TAG | delete REPO TAG [--force-shared] | gc" >&2
  exit 2
}

command_name="${1:-}"
case "${command_name}" in
  catalog)
    [[ $# -eq 1 ]] || usage
    registry_page_values '/v2/_catalog?n=1000' '.repositories[]?'
    ;;
  tags)
    [[ $# -eq 2 ]] || usage
    registry_list_tags "$2"
    ;;
  digest)
    [[ $# -eq 3 ]] || usage
    registry_validate_tag "$3"
    registry_manifest_digest "$2" "$3"
    ;;
  delete)
    [[ $# -eq 3 || ( $# -eq 4 && "$4" == '--force-shared' ) ]] || usage
    repo="$2"
    tag="$3"
    registry_validate_repo "${repo}"
    registry_validate_tag "${tag}"
    digest="$(registry_manifest_digest "${repo}" "${tag}")"
    shared_tags=()
    while IFS= read -r candidate; do
      [[ -n "${candidate}" ]] || continue
      candidate_digest="$(registry_manifest_digest "${repo}" "${candidate}")"
      if [[ "${candidate_digest}" == "${digest}" ]]; then
        shared_tags+=("${candidate}")
      fi
    done < <(registry_list_tags "${repo}")
    if (( ${#shared_tags[@]} > 1 )) && [[ "${4:-}" != '--force-shared' ]]; then
      registry_die "digest partagé par ${shared_tags[*]} ; suppression refusée sans --force-shared"
    fi
    registry_curl --request DELETE --output /dev/null \
      "${registry_base}/v2/${repo}/manifests/${digest}"
    echo "Digest ${digest} supprimé ; tags concernés : ${shared_tags[*]}"
    ;;
  gc)
    [[ $# -eq 1 ]] || usage
    exec "${script_dir}/registry/gc.sh"
    ;;
  *) usage ;;
esac
