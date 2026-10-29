#!/usr/bin/env bash
set -euo pipefail

registry_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
secret_dir="${registry_dir}/secrets"

if [[ -e "${secret_dir}/tls/ca.key" || -e "${secret_dir}/auth/users.htpasswd" ]]; then
  echo "Secrets déjà présents dans ${secret_dir} ; génération refusée pour éviter une rotation accidentelle." >&2
  exit 1
fi

umask 077
mkdir -p "${secret_dir}/tls" "${secret_dir}/auth"

openssl req -x509 -newkey rsa:3072 -noenc -sha256 -days 365 \
  -subj "/CN=Shop SAS TP CA" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" \
  -keyout "${secret_dir}/tls/ca.key" \
  -out "${secret_dir}/tls/ca.crt" 2>/dev/null

openssl req -newkey rsa:3072 -noenc \
  -subj "/CN=registry.local" \
  -keyout "${secret_dir}/tls/server.key" \
  -out "${secret_dir}/tls/server.csr" 2>/dev/null

cat > "${secret_dir}/tls/server.ext" <<'EOF'
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:registry.local,DNS:localhost,IP:127.0.0.1
EOF

openssl x509 -req -sha256 -days 365 \
  -in "${secret_dir}/tls/server.csr" \
  -CA "${secret_dir}/tls/ca.crt" \
  -CAkey "${secret_dir}/tls/ca.key" \
  -CAcreateserial \
  -extfile "${secret_dir}/tls/server.ext" \
  -out "${secret_dir}/tls/server.crt" 2>/dev/null

ci_password="${CI_PASSWORD:-$(openssl rand -hex 18)}"
dev_password="${DEV_PASSWORD:-$(openssl rand -hex 18)}"
if [[ "${ci_password}" =~ [[:space:]] || "${dev_password}" =~ [[:space:]] ]]; then
  echo "Les mots de passe ne doivent pas contenir d'espace (format netrc)." >&2
  exit 1
fi

printf '%s\n' "${ci_password}" | htpasswd -Bni -C 10 ci > "${secret_dir}/auth/ci.htpasswd"
cp "${secret_dir}/auth/ci.htpasswd" "${secret_dir}/auth/users.htpasswd"
printf '%s\n' "${dev_password}" | htpasswd -Bni -C 10 dev >> "${secret_dir}/auth/users.htpasswd"

printf 'CI_PASSWORD=%s\nDEV_PASSWORD=%s\n' "${ci_password}" "${dev_password}" > "${secret_dir}/auth/credentials.env"
printf 'machine registry.local login ci password %s\n' "${ci_password}" > "${secret_dir}/auth/ci.netrc"
printf 'machine registry.local login dev password %s\n' "${dev_password}" > "${secret_dir}/auth/dev.netrc"

chmod 600 "${secret_dir}/tls/ca.key" "${secret_dir}/tls/server.key" "${secret_dir}/auth/"*
chmod 644 "${secret_dir}/tls/ca.crt" "${secret_dir}/tls/server.crt"

echo "CA, certificat SAN registry.local et comptes bcrypt générés dans ${secret_dir} (ignoré par Git)."
