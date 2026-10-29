#!/usr/bin/env bash

registry_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY_HOST="${REGISTRY_HOST:-registry.local}"
REGISTRY_PORT="${REGISTRY_PORT:-5000}"
REGISTRY_IP="${REGISTRY_IP:-127.0.0.1}"
REGISTRY_CA_FILE="${REGISTRY_CA_FILE:-${registry_dir}/secrets/tls/ca.crt}"
REGISTRY_NETRC_FILE="${REGISTRY_NETRC_FILE:-${registry_dir}/secrets/auth/ci.netrc}"
registry_base="https://${REGISTRY_HOST}:${REGISTRY_PORT}"
manifest_accept='application/vnd.oci.image.index.v1+json,application/vnd.docker.distribution.manifest.list.v2+json,application/vnd.oci.image.manifest.v1+json,application/vnd.docker.distribution.manifest.v2+json'

registry_die() {
  echo "Erreur : $*" >&2
  exit 1
}

registry_require_tools() {
  command -v curl >/dev/null || registry_die "curl est requis"
  command -v jq >/dev/null || registry_die "jq est requis"
  [[ -f "${REGISTRY_CA_FILE}" ]] || registry_die "CA introuvable : ${REGISTRY_CA_FILE}"
  [[ -f "${REGISTRY_NETRC_FILE}" ]] || registry_die "netrc introuvable : ${REGISTRY_NETRC_FILE}"
}

registry_validate_repo() {
  [[ "$1" =~ ^[a-z0-9]+([._/-][a-z0-9]+)*$ ]] || registry_die "nom de dépôt invalide : $1"
}

registry_validate_tag() {
  [[ "$1" =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$ ]] || registry_die "tag invalide : $1"
}

registry_validate_digest() {
  [[ "$1" =~ ^sha256:[0-9a-f]{64}$ ]] || registry_die "digest invalide : $1"
}

registry_curl() {
  local args=(--silent --show-error --fail-with-body --cacert "${REGISTRY_CA_FILE}" --netrc-file "${REGISTRY_NETRC_FILE}" --noproxy "${REGISTRY_HOST}")
  if [[ -n "${REGISTRY_IP}" ]]; then
    args+=(--resolve "${REGISTRY_HOST}:${REGISTRY_PORT}:${REGISTRY_IP}")
  fi
  curl "${args[@]}" "$@"
}

registry_page_values() {
  local next="$1" expression="$2" headers body link
  while [[ -n "${next}" ]]; do
    headers="$(mktemp)"
    body="$(registry_curl --dump-header "${headers}" "${registry_base}${next}")" || {
      rm -f "${headers}"
      return 1
    }
    jq -r "${expression}" <<< "${body}"
    link="$(awk 'tolower($1)=="link:" {$1=""; print}' "${headers}" | tr -d '\r')"
    rm -f "${headers}"
    next="$(sed -n 's/.*<\([^>]*\)>.*/\1/p' <<< "${link}")"
    if [[ "${next}" == "${registry_base}"* ]]; then
      next="${next#"${registry_base}"}"
    fi
    [[ -z "${next}" || "${next}" == /* ]] || registry_die "lien de pagination externe refusé"
  done
}

registry_list_tags() {
  registry_validate_repo "$1"
  registry_page_values "/v2/$1/tags/list?n=1000" '.tags[]?'
}

registry_manifest_digest() {
  local repo="$1" reference="$2" headers digest
  registry_validate_repo "${repo}"
  headers="$(mktemp)"
  registry_curl --head --header "Accept: ${manifest_accept}" --dump-header "${headers}" --output /dev/null \
    "${registry_base}/v2/${repo}/manifests/${reference}" || {
      rm -f "${headers}"
      return 1
    }
  digest="$(awk 'tolower($1)=="docker-content-digest:" {print $2}' "${headers}" | tr -d '\r' | tail -1)"
  rm -f "${headers}"
  registry_validate_digest "${digest}"
  printf '%s\n' "${digest}"
}

registry_manifest_body() {
  local repo="$1" reference="$2"
  registry_validate_repo "${repo}"
  registry_curl --header "Accept: ${manifest_accept}" "${registry_base}/v2/${repo}/manifests/${reference}"
}

registry_tag_created() {
  local repo="$1" tag="$2" manifest child config_digest
  manifest="$(registry_manifest_body "${repo}" "${tag}")"
  if jq -e '.manifests | type == "array"' >/dev/null <<< "${manifest}"; then
    child="$(jq -r 'first(.manifests[] | select(.platform.os == "linux") | .digest) // empty' <<< "${manifest}")"
    [[ -n "${child}" ]] || return 1
    manifest="$(registry_manifest_body "${repo}" "${child}")"
  fi
  config_digest="$(jq -r '.config.digest // empty' <<< "${manifest}")"
  [[ -n "${config_digest}" ]] || return 1
  registry_validate_digest "${config_digest}"
  registry_curl "${registry_base}/v2/${repo}/blobs/${config_digest}" | jq -r '.created // empty'
}
