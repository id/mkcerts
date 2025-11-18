# Scripts to create a set of self-signed certificates, or issue a Let's Encrypt one

## Self-signed certificates

Simple usage

```
./ca.sh
./server.sh my.domain.com
./client.sh my.cn
```

Customized

```
./ca.sh MyCA                   # saved to MyCA dir
./server.sh my.domain.com MyCA # saved to my.domain.com dir
./client.sh my.cn MyCA         # saved to my.cn dir
```

## Start EMQX in docker container with generated certificates

```bash
docker run -d --name emqx --hostname=my.domain.com \
  -e EMQX_NAME=emqx \
  -e EMQX_HOST=my.domain.com \
  -e EMQX_NODE_COOKIE=testcookie \
  -e EMQX_listeners__ssl__default__ssl_options__cacertfile=/certs/ca/ca.pem \
  -e EMQX_listeners__ssl__default__ssl_options__certfile=/certs/server/server.pem \
  -e EMQX_listeners__ssl__default__ssl_options__keyfile=/certs/server/server.key \
  -e EMQX_listeners__ssl__default__ssl_options__verify=verify_peer \
  -e EMQX_listeners__ssl__default__ssl_options__fail_if_no_peer_cert=true \
  -v $(pwd)/MyCA:/certs/ca:ro \
  -v $(pwd)/my.domain.com:/certs/server:ro \
  -p 1883:1883 \
  -p 8883:8883 \
  -p 8083:8083 \
  -p 8084:8084 \
  -p 18083:18083 \
  emqx/emqx-enterprise:6.0.1
```

## Let's Encrypt certificates

Uses [acme.sh](https://github.com/acmesh-official/acme.sh).
Requires access to DNS management to create a TXT record.

```
./letsencrypt.sh my.domain.com
```
