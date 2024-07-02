#!/usr/bin/env bash

set -euo pipefail

domain="$1"

dir=selfsigned
mkdir -p ${dir}

# generate password
pass=$(openssl rand -base64 32)

# echo "Generating CA..."
# openssl genpkey -algorithm RSA -out ${dir}/ca.key.enc -aes256 -pass pass:${pass}
# openssl req -x509 -new -nodes -key ${dir}/ca.key.enc -sha256 -days 3650 -out ${dir}/ca.pem -passin pass:${pass} \
#         -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=MyCA" \
#         -addext 'keyUsage = cRLSign, keyCertSign, digitalSignature' \
#         -addext 'extendedKeyUsage = critical, serverAuth, clientAuth, codeSigning, emailProtection, timeStamping' \
#         -addext 'subjectKeyIdentifier=hash' \
#         -addext 'authorityKeyIdentifier=keyid:always,issuer:always' \
#         -addext "basicConstraints = critical, CA:TRUE"

# echo "Generating Server certificate..."
# cat > /tmp/server_ext.cnf <<EOF
# authorityKeyIdentifier=keyid,issuer
# basicConstraints=CA:FALSE
# keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
# extendedKeyUsage = serverAuth
# subjectAltName = @alt_names

# [alt_names]
# DNS.1 = ${domain}
# EOF
# openssl genpkey -algorithm RSA -out ${dir}/server.key.enc -aes256 -pass pass:${pass}
# openssl req -new -key ${dir}/server.key.enc -out ${dir}/server.csr -passin pass:${pass} -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=${domain}"
# openssl x509 -req -in ${dir}/server.csr -CA ${dir}/ca.pem -CAkey ${dir}/ca.key.enc -CAcreateserial -out ${dir}/server.pem -days 825 -sha256 -extfile /tmp/server_ext.cnf -passin pass:${pass}

echo "Generating Client certificate..."
cat > /tmp/client_ext.cnf <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
EOF
openssl genpkey -algorithm RSA -out ${dir}/client.key.enc -aes256 -pass pass:${pass}
openssl req -new -key ${dir}/client.key.enc -out ${dir}/client.csr -passin pass:${pass} -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=${domain}"
openssl x509 -req -in ${dir}/client.csr -CA ${dir}/ca.pem -CAkey ${dir}/ca.key -CAcreateserial -out ${dir}/client.pem -days 825 -sha256 -extfile /tmp/client_ext.cnf

rm -f ${dir}/ca.srl || true
rm -f ${dir}/*.csr || true

# openssl rsa -in ${dir}/ca.key.enc -out ${dir}/ca.key -passin pass:${pass}
# openssl rsa -in ${dir}/server.key.enc -out ${dir}/server.key -passin pass:${pass}
openssl rsa -in ${dir}/client.key.enc -out ${dir}/client.key -passin pass:${pass}
rm -f ${dir}/*.key.enc

# cat ${dir}/server.pem ${dir}/ca.pem > ${dir}/server-bundle.pem
cat ${dir}/client.pem ${dir}/ca.pem > ${dir}/client-bundle.pem
