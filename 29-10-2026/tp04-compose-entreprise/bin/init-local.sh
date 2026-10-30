#!/usr/bin/env sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
mkdir -p "$project_dir/secrets"
umask 077

if [ ! -f "$project_dir/secrets/db_password.txt" ]; then
  openssl rand -hex 24 > "$project_dir/secrets/db_password.txt"
fi
if [ ! -f "$project_dir/secrets/pip.conf" ]; then
  cat > "$project_dir/secrets/pip.conf" <<'EOF'
[global]
index-url = https://pypi.org/simple
EOF
fi
if [ ! -f "$project_dir/.env" ]; then
  cp "$project_dir/.env.example" "$project_dir/.env"
fi
chmod 600 "$project_dir/secrets/db_password.txt" "$project_dir/secrets/pip.conf"
echo 'Configuration locale prête (.env et secrets/ ignorés par Git).'
