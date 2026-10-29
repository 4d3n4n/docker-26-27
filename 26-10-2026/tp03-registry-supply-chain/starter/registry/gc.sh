#!/usr/bin/env bash
set -euo pipefail

registry_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${registry_dir}"

restart_services() {
  docker compose up -d registry gateway ui
}

docker compose stop ui gateway registry
trap restart_services EXIT
docker compose run --rm --no-deps --entrypoint registry registry \
  garbage-collect /etc/docker/registry/config.yml
