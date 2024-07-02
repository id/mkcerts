#!/usr/bin/env bash

set -euo pipefail

domain="$1"
ca_cn="${2:-MyCA}"
dir="${3:-./$domain}"
mkdir -p ${dir}

# generate password
pass=$(openssl rand -base64 32)

echo "Generating Server certificate..."
cat > /tmp/server_ext.cnf <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${domain}
EOF

openssl genpkey -algorithm RSA -out "${dir}/server.key.enc" -aes256 -pass "pass:${pass}"
openssl req -new -key "${dir}/server.key.enc" -out "${dir}/server.csr" -passin "pass:${pass}" -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=${domain}"
openssl x509 -req -in "${dir}/server.csr" -CA "${ca_cn}/ca.pem" -CAkey "${ca_cn}/ca.key" -CAcreateserial -out "${dir}/server.pem" -days 825 -sha256 -extfile /tmp/server_ext.cnf

rm -f ${dir}/*.csr || true

openssl rsa -in "${dir}/server.key.enc" -out "${dir}/server.key" -passin pass:${pass}
rm -f ${dir}/*.key.enc
cat "${dir}/server.pem" "${ca_cn}/ca.pem" > "${dir}/server-bundle.pem"
