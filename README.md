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

## Let's Encrypt certificates

Uses [acme.sh](https://github.com/acmesh-official/acme.sh).
Requires access to DNS management to create a TXT record.

```
./letsencrypt.sh my.domain.com
```
