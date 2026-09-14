# Networking

## External Traffic Flow

```
Internet → Cloudflare Tunnel (cfb4f951) → localhost:443 → Traefik → service:port
```

- All WAN traffic enters via Cloudflare tunnel — no open firewall ports needed.
- Traefik terminates TLS (LetsEncrypt certs via DNS challenge).
- Every external subdomain needs **both**: a Cloudflare ingress entry AND a Traefik router.
- DNS resolution for `*.youssefalhassan.com` is a **wildcard CNAME** (see DNS section below) — a new subdomain does NOT need its own DNS record, only the tunnel ingress entry + Traefik router.

## Internal (LAN)

- Pi IP: `192.168.0.69`
- Grafana: `192.168.0.69:3000`
- Postgres: `192.168.0.69:5432`
- Direct service access by LAN IP:port, no proxy needed.

## Container Networks

| Network | File | Used by |
|---------|------|---------|
| `postgres` | `postgres.network` | postgres, monetr, authelia |
| `observability` | `observability.network` | prometheus, loki, grafana, alloy |
| `dario` | `dario.network` | dario (Claude proxy) `http://dario:3456`, codex (ChatGPT/Codex proxy) `http://codex:8787`, hermes, open-webui; join from client containers to reach either LLM endpoint. **All members disabled 2026-09-14 — network definition retained (see `docs/services.md` Disabled table).** |
| `odysseus` | `odysseus.network` | odysseus, odysseus-chromadb, odysseus-searxng, odysseus-ntfy. **Entire stack disabled 2026-09-14 — network definition retained (see `docs/services.md` Disabled table).** |
| `host` | (native) | traefik, home-assistant |

## DNS

### Cloudflare wildcard (WAN)

`youssefalhassan.com` has a wildcard DNS record in the Cloudflare dashboard:

```
*.youssefalhassan.com  CNAME  cfb4f951-81ba-415b-9846-9273b523631d.cfargotunnel.com  (proxied)
```

Added 2026-07-08 while registering `ai.youssefalhassan.com`, to stop needing a one-off CNAME per subdomain (previously required manually for e.g. Hermes and Odysseus — see `docs/services.md`). This record only gets DNS resolution to the tunnel; the tunnel itself still needs a matching `hostname:` entry in `/etc/cloudflared/config.yml` for a given subdomain to route anywhere instead of hitting the catch-all `http_status:404`. So the DNS step of "Adding a Subdomain" (below) is now a no-op for every subdomain, but the ingress-entry step is still required per service.

### Pi-hole (LAN)

Pi-hole handles LAN DNS (native `pihole-FTL` v6, config `/etc/pihole/pihole.toml`). Upstream: Cloudflare (`1.1.1.1`).

LAN-only services (no Cloudflare tunnel) get a Pi-hole local DNS record pointing the subdomain at the Pi's LAN IP, plus a Traefik router. Let's Encrypt certs still issue because the resolver uses DNS-01 via Cloudflare API. Current LAN-only subdomains:
- `transmission.youssefalhassan.com` → Traefik → `127.0.0.1:9091`
- `jackett.youssefalhassan.com` → Traefik → `127.0.0.1:9117`

### Split-horizon for all `*.youssefalhassan.com` (local-first)

`pihole.toml` → `misc.dnsmasq_lines` pins the whole zone to the Pi so LAN clients reach Traefik directly instead of hairpinning through the Cloudflare tunnel:

```toml
dnsmasq_lines = [
  "filter-rr=64,65",                             # drop SVCB/HTTPS records network-wide — kills the ECH leak; see below
  "address=/youssefalhassan.com/192.168.0.69",   # A  → Pi (Traefik terminates TLS with the real LE cert)
  "address=/youssefalhassan.com/::",             # AAAA → sinkhole; MUST keep — see below
  "server=/storybook.youssefalhassan.com/#",     # carve-out → resolve upstream (Cloudflare), not the Pi
  "server=/vw.youssefalhassan.com/#",            # carve-out → Vaultwarden via Cloudflare tunnel on LAN too
  "server=/itar.youssefalhassan.com/#"           # carve-out → Cloudflare Pages app (not hosted on the Pi)
]
```

**Per-host carve-outs (`server=/host/#`):** the zone-wide `address=/youssefalhassan.com/...` lines catch **every** subdomain, including names that don't live on the Pi (e.g. a Cloudflare Pages app) or that you deliberately want LAN clients to reach via the Cloudflare tunnel. dnsmasq resolves by longest-domain match, so a more-specific `server=/<host>.youssefalhassan.com/#` overrides the wildcard for that one name; `#` means "use the configured upstream" (Cloudflare), returning the real A/AAAA that the outside world sees. Add one line per name and `sudo systemctl restart pihole-FTL`. Current carve-outs: `storybook` (Pages), `vw` (Vaultwarden — chosen to hairpin through the tunnel on LAN), `itar` (Pages). Note: a carve-out's AAAA is no longer sinkholed — it returns Cloudflare's real IPv6, which is fine because the client reaches Cloudflare over both v4 and v6 (no split-brain), *not* Traefik directly.

**Why the `::` line matters (was the cause of a self-signed-cert outage on `fin.`):** FTL only applies the IPv4 `address=` override to A queries — AAAA queries for these names leak upstream and return Cloudflare's real IPv6. The Pi has **no IPv6**, so a dual-stack browser split-brains: it reaches Cloudflare over v6 (valid cert + HSTS pin) but Traefik directly over v4. Any moment Traefik serves its `TRAEFIK DEFAULT CERT` (self-signed fallback for an unmatched SNI, e.g. during a restart before `acme.json` loads) then becomes an **unbypassable** `MOZILLA_PKIX_ERROR_SELF_SIGNED_CERT` block because of the HSTS pin. The `::` sinkhole makes FTL authoritative for AAAA, so browsers fail-fast on v6 and consistently use IPv4 → Traefik → valid cert. Apply changes with `sudo systemctl restart pihole-FTL`.

**Why the `filter-rr=64,65` line matters (was the cause of an `SSL_ERROR_BAD_CERT_DOMAIN` on `vw.`):** the `address=` override rewrites **only A/AAAA** — it does *not* touch the type-65 `HTTPS` (and type-64 `SVCB`) record, which leaks upstream and returns Cloudflare's, complete with an `ech=` (Encrypted Client Hello) config whose public name is `cloudflare-ech.com`. A dual-stack, ECH-capable browser (Zen/Firefox, ECH on by default) then resolves `vw` → Pi via the A override but, seeing the ECH config, opens the TLS connection to the Pi with an **outer SNI of `cloudflare-ech.com`** instead of `vw.…`. Traefik doesn't speak ECH, matches no router for that SNI, and falls back to the **store default cert** (the `*.youssefalhassan.com` wildcard) — producing an SNI/cert mismatch the browser reports as an impersonation warning (`SSL_ERROR_BAD_CERT_DOMAIN`, "valid for `*.youssefalhassan.com, youssefalhassan.com`"). It only happens on the LAN; externally the browser really reaches Cloudflare, which *does* support ECH. `filter-rr=64,65` makes FTL strip SVCB/HTTPS records network-wide, so no `ech=` reaches LAN clients and browsers connect with a plaintext `Host`-matching SNI → Traefik serves the per-host cert. Trade-off: disables ECH and SVCB-based HTTP/3 fast-discovery network-wide (browsers still find h3 via `Alt-Svc`); accumulates with FTL's own `filter-rr=ANY`. Apply with `sudo systemctl restart pihole-FTL`; a browser that cached the bad HTTPS record/error needs its DNS+site state cleared (or wait out the record TTL).

### Traefik default certificate — closes the restart self-signed window

The `::` sinkhole removes the IPv6 split-brain, but the **self-signed-during-restart** half of that failure remained: measured with a 50 ms probe across a `systemctl --user restart traefik`, there is a sub-second window where `:443` is back up but per-host certs have not yet loaded from `acme.json`, and Traefik serves its self-signed `TRAEFIK DEFAULT CERT`. A browser reconnecting in that window (open Home Assistant / Jellyfin / Vaultwarden tabs retry aggressively) gets the sticky HSTS cert error again on the LAN direct path — i.e. the problem comes back on every restart/reboot until the browser's state is cleared.

Fix — serve a **valid wildcard as the store's default certificate**, delivered by the *file* provider (which loads before the ACME certs), so the self-signed cert is never served:

- `dynamic/tls.yml` → `tls.stores.default.defaultCertificate` points at `certs/default.{crt,key}`.
- Those PEM files are the `*.youssefalhassan.com` wildcard, mirrored from `acme.json` by `extract-default-cert.py`.
- The wildcard is issued/auto-renewed by the `tls.domains` block on the `traefik-dashboard` router in `services.yml`. (`defaultCertificate` and `defaultGeneratedCert` are mutually exclusive in Traefik — the warning `cannot be defined at the same time` — so renewal is driven from a router, not from the store.)
- `traefik-default-cert.timer` (systemd `--user`, daily) re-runs the mirror so a renewed wildcard is copied to PEM; on change it touches `tls.yml` to trigger a hot-reload.

Verified: after the fix, a 50 ms restart probe of `ha`/`jf` shows only valid-cert (`ssl_verify=0`) or brief connection-refused samples — **zero** self-signed samples. Connection-refused during the ~1 s restart is harmless (browser retries against a valid cert); it does not pin HSTS.

Files: `traefik/dynamic/tls.yml`, `traefik/extract-default-cert.py`, `traefik/certs/`, `~/.config/systemd/user/traefik-default-cert.{service,timer}`.

## Traefik Routes

File: `~/infra/traefik/dynamic/services.yml`  
Traefik hot-reloads this file — no restart needed after edits.

Pattern for a new service:
```yaml
http:
  routers:
    myservice:
      rule: "Host(`myservice.youssefalhassan.com`)"
      entryPoints: [websecure]
      service: myservice
      middlewares: [authelia]          # omit if public
      tls:
        certResolver: letsencrypt

  services:
    myservice:
      loadBalancer:
        servers:
          - url: "http://127.0.0.1:PORT"
```

## Cloudflare Tunnel — Adding a Subdomain

File: `/etc/cloudflared/config.yml` (requires `sudo`)

No DNS record needed — the wildcard CNAME (see DNS section above) already covers any `*.youssefalhassan.com` hostname. Just add the ingress entry:

Add before the catch-all `http_status:404` line:
```yaml
- hostname: myservice.youssefalhassan.com
  service: https://localhost:443
  originRequest:
    originServerName: myservice.youssefalhassan.com
```

Then restart: `sudo systemctl restart cloudflared`
