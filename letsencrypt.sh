#!/usr/bin/env bash

domain="$1"
dir="${2:-./$domain}"
mkdir -p $dir

# Install acme.sh
if [ ! -f acme.sh ]; then
    curl -sSLf https://raw.githubusercontent.com/acmesh-official/acme.sh/master/acme.sh > acme.sh
    chmod +x acme.sh
fi

./acme.sh --issue --dns -d "$domain" --server letsencrypt --yes-I-know-dns-manual-mode-enough-go-ahead-please --force
read -p "Press enter when you are ready..."
./acme.sh --issue --dns -d "$domain" --server letsencrypt --yes-I-know-dns-manual-mode-enough-go-ahead-please --renew

cp -r ~/.acme.sh/${domain}*/ca.cer ${dir}/ca.pem
cp -r ~/.acme.sh/${domain}*/${domain}.cer ${dir}/server.pem
cp -r ~/.acme.sh/${domain}*/fullchain.cer ${dir}/server-bundle.pem
cp -r ~/.acme.sh/${domain}*/${domain}.key ${dir}/server.key
