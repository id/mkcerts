#!/usr/bin/env bash

set -euo pipefail

cn="${1:-MyCA}"
dir="${2:-./$cn}"
mkdir -p ${dir}

# generate password
pass=$(openssl rand -base64 32)

echo "Generating CA..."
openssl genpkey -algorithm RSA -out ${dir}/ca.key.enc -aes256 -pass pass:${pass}
openssl req -x509 -new -nodes -key ${dir}/ca.key.enc -sha256 -days 3650 -out ${dir}/ca.pem -passin pass:${pass} \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=MyCA" \
        -addext 'keyUsage = cRLSign, keyCertSign, digitalSignature' \
        -addext 'extendedKeyUsage = critical, serverAuth, clientAuth, codeSigning, emailProtection, timeStamping' \
        -addext 'subjectKeyIdentifier=hash' \
        -addext 'authorityKeyIdentifier=keyid:always,issuer:always' \
        -addext "basicConstraints = critical, CA:TRUE"

rm -f ${dir}/ca.srl || true
rm -f ${dir}/*.csr || true

openssl rsa -in ${dir}/ca.key.enc -out ${dir}/ca.key -passin pass:${pass}
rm -f ${dir}/*.key.enc
