# Authelia secrets

This directory is gitignored entirely — every file in it is raw key material with
no template beyond "random bytes" or "a PEM key," so there's nothing meaningful to
commit as a `.example`. Regenerate them with:

```bash
# Random secrets (session, JWT, storage encryption, HMAC)
openssl rand -hex 64 > session_secret
openssl rand -hex 64 > jwt_secret
openssl rand -hex 64 > storage_encryption_key
openssl rand -hex 64 > oidc_hmac_secret

# OIDC JWKS signing key (referenced by authelia/configuration.yml)
openssl genrsa -out oidc_private_key.pem 4096

chmod 600 session_secret jwt_secret storage_encryption_key oidc_hmac_secret oidc_private_key.pem
```

`nextcloud_oidc_secret_hash` is not actually read by Authelia — the client secret hash
lives inline in `authelia/configuration.yml` (`identity_providers.oidc.clients[].client_secret`).
Regenerate it with:

```bash
authelia crypto hash generate pbkdf2 --password '<NC_OIDC_CLIENT_SECRET from nextcloud/.env>'
```
