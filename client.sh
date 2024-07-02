#!/usr/bin/env bash

set -euo pipefail

cn="$1"
ca_cn="${2:-MyCA}"
dir="${3:-./$cn}"
mkdir -p ${dir}

# generate password
pass=$(openssl rand -base64 32)

echo "Generating Client certificate..."
cat > /tmp/client_ext.cnf <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
EOF
openssl genpkey -algorithm RSA -out ${dir}/client.key.enc -aes256 -pass pass:${pass}
openssl req -new -key ${dir}/client.key.enc -out ${dir}/client.csr -passin pass:${pass} -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=${cn}"
openssl x509 -req -in ${dir}/client.csr -CA "${ca_cn}/ca.pem" -CAkey "${ca_cn}/ca.key" -CAcreateserial -out ${dir}/client.pem -days 825 -sha256 -extfile /tmp/client_ext.cnf

rm -f ${dir}/*.csr || true

openssl rsa -in ${dir}/client.key.enc -out ${dir}/client.key -passin pass:${pass}
rm -f ${dir}/*.key.enc
cat ${dir}/client.pem ${ca_cn}/ca.pem > ${dir}/client-bundle.pem
