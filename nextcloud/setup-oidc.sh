#!/bin/bash
# Run this ONCE after Nextcloud has fully initialized (check logs first).
# It installs the user_oidc app and wires it to Authelia.
set -e

# Sourced from nextcloud/.env (NC_OIDC_CLIENT_SECRET) — must match the
# pbkdf2-sha512 hash configured in authelia/configuration.yml.
NC_OIDC_CLIENT_SECRET="${NC_OIDC_CLIENT_SECRET:?Set NC_OIDC_CLIENT_SECRET first, e.g. export \$(grep NC_OIDC_CLIENT_SECRET .env)}"
AUTHELIA_DISCOVERY="https://auth.youssefalhassan.com/.well-known/openid-configuration"

# Install user_oidc app (skip if already installed)
podman exec --user www-data nextcloud php occ app:install user_oidc 2>/dev/null || true
podman exec --user www-data nextcloud php occ app:enable user_oidc 2>/dev/null || true

# Configure the Authelia provider
podman exec --user www-data nextcloud php occ user_oidc:provider Authelia \
  --clientid="nextcloud" \
  --clientsecret="$NC_OIDC_CLIENT_SECRET" \
  --discoveryuri="$AUTHELIA_DISCOVERY" \
  --mapping-uid="preferred_username" \
  --mapping-display-name="name" \
  --mapping-email="email" \
  --mapping-groups="groups"

# Trust Authelia as the sole login source (disable Nextcloud's own login form)
# Comment out the next line if you want to keep Nextcloud login as fallback
podman exec --user www-data nextcloud php occ config:app:set user_oidc allow_multiple_user_backends --value="0"

# Reverse proxy settings (ensure HTTPS is trusted)
podman exec --user www-data nextcloud php occ config:system:set overwriteprotocol --value="https"
podman exec --user www-data nextcloud php occ config:system:set overwritecliurl --value="https://cloud.youssefalhassan.com"

echo ""
echo "Done. Visit https://cloud.youssefalhassan.com and log in via Authelia."
echo "The 'admin' local account (password in ~/infra/nextcloud/.env) remains as emergency fallback."
