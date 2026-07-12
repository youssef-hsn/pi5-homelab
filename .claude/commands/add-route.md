Add a Traefik route (and optional Cloudflare ingress) for a service that's already running. Arguments: $ARGUMENTS

Parse arguments as: `<service-name> <local-port> <subdomain> [--no-auth] [--lan-only]`
- `--no-auth`: skip Authelia middleware
- `--lan-only`: add Traefik route only, skip Cloudflare (LAN access only)

## Steps to perform

1. **Add Traefik router + service** to `~/infra/traefik/dynamic/services.yml`:
   ```yaml
   routers:
     <service-name>:
       rule: "Host(`<subdomain>.youssefalhassan.com`)"
       entryPoints: [websecure]
       service: <service-name>
       middlewares: [authelia]   # omit if --no-auth
       tls:
         certResolver: letsencrypt
   services:
     <service-name>:
       loadBalancer:
         servers:
           - url: "http://127.0.0.1:<port>"
   ```
   Traefik hot-reloads — no restart needed.

2. **Add Cloudflare ingress** (skip if `--lan-only`) — insert before catch-all in `/etc/cloudflared/config.yml`:
   ```yaml
   - hostname: <subdomain>.youssefalhassan.com
     service: https://localhost:443
     originRequest:
       originServerName: <subdomain>.youssefalhassan.com
   ```
   Then: `sudo systemctl restart cloudflared`

3. **Update docs** — mandatory:
   - Update the service's row in `docs/services.md` to add the subdomain column.
   - Update the Cloudflare Tunnel Ingress table if applicable.
   - Update `docs/networking.md` Traefik Routes section if a new pattern was used.

Show a summary of every file changed at the end.
