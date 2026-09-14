# Service Registry

Last updated: 2026-09-14

## Active Services

| Service | Port (local) | Subdomain | Quadlet | Notes |
|---------|-------------|-----------|---------|-------|
| Traefik v3 | 80, 443 (host) | `proxy.youssefalhassan.com` | `traefik.container` | Reverse proxy, host-network, LetsEncrypt via DNS. Serves a `*.youssefalhassan.com` wildcard as the store **default cert** (`dynamic/tls.yml` → `certs/default.{crt,key}`, mirrored from `acme.json` by `extract-default-cert.py` / `traefik-default-cert.timer`) so no self-signed cert is served during the restart window — see `docs/networking.md`. |
| Authelia | 127.0.0.1:9100 | `auth.youssefalhassan.com` | `authelia.container` | SSO / forward-auth middleware |
| VaultWarden | 127.0.0.1:8081 | `vw.youssefalhassan.com` | `vaultwarden.container` | Password manager; data in `infra/vault-warden/data` (note hyphenated dir) |
| Home Assistant | 127.0.0.1:8123 (host-net) | `ha.youssefalhassan.com` | `home-assistant.container` | Smart home |
| Monetr | 127.0.0.1:4000 | `mm.youssefalhassan.com` | *(check systemd)* | Financial app; depends on postgres |
| Jellyfin | 127.0.0.1:8096 | `jf.youssefalhassan.com` | `jellyfin.container` | Media server |
| PostgreSQL 16 | 192.168.0.69:5432 | — | `postgres.container` | Shared DB; network `postgres.network` |
| Pi-hole | LAN | — | baremetal (system service) | DNS + DHCP; not containerized |
| Syncthing | 127.0.0.1:8384 | — | — | File sync (LAN only); on hold, not yet deployed |
| Nextcloud | 127.0.0.1:8082 | `cloud.youssefalhassan.com` | `infra/nextcloud/nextcloud.container` | File sync/cloud; OIDC via Authelia; always-on; custom image `localhost/nextcloud-memories:latest` built from `infra/nextcloud/Containerfile` adds ffmpeg + exiftool for the Memories app |
| Alloy | 127.0.0.1:12345 | — | `alloy.container` | Ships journald logs + host metrics (node-exporter) to **Grafana Cloud**; credentials in `observability/alloy/credentials.env` |
| Nefarious | 127.0.0.1:8002 | `nefarious.youssefalhassan.com` | `nefarious.container` | Media manager; depends on nefarious-redis, jackett, transmission |
| Nefarious Redis | internal | — | `nefarious-redis.container` | Redis broker for Nefarious celery workers |
| Jackett | 127.0.0.1:9117 | `jackett.youssefalhassan.com` (LAN-only via Pi-hole DNS) | `jackett.container` | Torrent indexer used by Nefarious; container name `jackett` (matches nefarious DB setting); on nefarious.network |
| Transmission | 127.0.0.1:9091 | `transmission.youssefalhassan.com` (LAN-only via Pi-hole DNS) | `transmission.container` | Torrent downloader used by Nefarious; container name `transmission` (matches nefarious DB setting); ports 9091, 51413 |
| Nefarious Celery | internal | — | `nefarious-celery.container` | Background download worker; uses `Entrypoint=/app/entrypoint-celery.sh` to override the image's web entrypoint |
| Nefarious Celery Scheduler | internal | — | `nefarious-celery-scheduler.container` | Celery beat scheduler; uses `Entrypoint=/app/entrypoint-celery.sh` |
| FlareSolverr | 127.0.0.1:8191 | — | `flaresolverr.container` | Shared Cloudflare bypass proxy; on nefarious.network; reachable at http://flaresolverr:8191 from same network or http://127.0.0.1:8191 from host |
| Memos | 127.0.0.1:5230 | `memos.youssefalhassan.com` | `memos.container` | Lightweight note/memo hub (`docker.io/neosmemo/memos:stable`). **Uses the shared PostgreSQL server** (`postgres.network`, DB `memos`, role `memos`) via `MEMOS_DRIVER=postgres` + `MEMOS_DSN` (config `infra/memos/memos.env`; DB password mirrored in `postgres/.env` `MEMOS_DB_PASSWORD`, init parity in `postgres/initdb/03-memos.sh`). Local working dir (uploaded resources/thumbnails) in volume `memos-data` (`/var/opt/memos`) — the data itself lives in Postgres. Own auth — first account created on `https://memos.youssefalhassan.com` becomes host/admin; **disable signups afterward** (Settings → Workspace → disallow user signup) since this is public via Cloudflare with no Authelia gate. |

## Disabled / On-Hold Services

| Service | Reason | Re-enable |
|---------|--------|-----------|
| Nginx | Replaced by Traefik (2026-04-19). Configs preserved. | `sudo systemctl stop cloudflared && systemctl --user stop traefik && sudo systemctl enable --now nginx` |
| Syncthing | Not yet deployed; on hold. | Add quadlet when ready. |
| Grafana (local) | Disabled 2026-05-10 — migrated to Grafana Cloud. Quadlet preserved at `grafana.container.disabled`. | `mv ~/.config/containers/systemd/grafana.container.disabled ~/.config/containers/systemd/grafana.container && systemctl --user daemon-reload && systemctl --user start grafana` |
| Loki (local) | Disabled 2026-05-10 — logs now ship to Grafana Cloud Loki. Quadlet preserved at `loki.container.disabled`. Volume `loki-data` retained. | Restore quadlet, daemon-reload, start. Re-point Alloy `loki.write` at `http://loki:3100`. |
| Prometheus (local) | Disabled 2026-05-03; never restored — Grafana Cloud Prometheus is now the metrics store. Quadlet preserved at `prometheus.container.disabled`. | Restore quadlet, daemon-reload, start. |
| Pyroscope (local) | Disabled 2026-05-10 — profiling not currently shipped to Grafana Cloud (would need Pyroscope endpoint + scrape config in Alloy). Quadlet preserved at `pyroscope.container.disabled`. Volume `pyroscope-data` retained. | Restore quadlet, daemon-reload, start. Re-add `pyroscope.scrape` + `pyroscope.write` blocks in `alloy/config.alloy`. |
| Sablier | Removed 2026-06-22 — container sleep/wake proxy dropped; all services now always-on. Files kept as backlog: quadlet `sablier.container.disabled`, middlewares `traefik/dynamic/sablier.yml.disabled`, config dir `traefik/sablier/`, and `.claude/commands/add-sablier.md`. | Restore both `.disabled` files (drop suffix), re-add the `experimental.plugins.sablier` block to `traefik.yml`, re-attach `middlewares: [sablier-*]` to the desired routers in `services.yml`, daemon-reload, start `sablier`, restart `traefik`. |
| Firefly III | Disabled 2026-09-14 — not in use. Quadlet at `firefly.container.disabled`; Traefik router+service and Cloudflare `fin` ingress commented (`# DISABLED 2026-09-14`). Config/`storage` dir + postgres `firefly` DB retained. | `mv ~/.config/containers/systemd/firefly.container.disabled ~/.config/containers/systemd/firefly.container`, then `/enable-service firefly` (uncomments route + `fin` ingress, reloads, starts). |
| Open WebUI | Disabled 2026-09-14 — not in use. Quadlet at `open-webui.container.disabled`; Traefik router+service and Cloudflare `ai` ingress commented. Volume `open-webui-data` (chats/users/embeddings) retained. **Needs dario + codex running.** | Restore quadlet name, re-enable **dario** + **codex** first, then `/enable-service open-webui`. |
| Hermes Agent | Disabled 2026-09-14 — not in use. Quadlet at `hermes.container.disabled`; Traefik router+service and Cloudflare `hermes` ingress commented. Volume `hermes-data` retained. **Needs dario running** (`Requires=dario.service`). Middleware `hermes-login-redirect` left defined (orphaned) in `dynamic/middlewares.yml`. | Restore quadlet name, re-enable **dario** first, then `/enable-service hermes`. |
| Dario | Disabled 2026-09-14 — not in use (its consumers Open WebUI + Hermes also disabled). Quadlet at `dario.container.disabled`; internal-only, no Traefik/Cloudflare route. Volume `dario-data` (OAuth pool) + `dario.network` retained. | `mv ~/.config/containers/systemd/dario.container.disabled ~/.config/containers/systemd/dario.container && systemctl --user daemon-reload && systemctl --user start dario`. |
| Codex | Disabled 2026-09-14 — not in use (consumer Open WebUI also disabled). Quadlet at `codex.container.disabled`; internal-only, no Traefik/Cloudflare route. Volume `codex-data` (OAuth pool) retained; on `dario.network`. Image `localhost/codex-proxy:latest` still built. | `mv ~/.config/containers/systemd/codex.container.disabled ~/.config/containers/systemd/codex.container && systemctl --user daemon-reload && systemctl --user start codex`. |
| Odysseus | Disabled 2026-09-14 — full stack turned off; not in use. Quadlet at `odysseus.container.disabled`; Traefik router+service commented (`# DISABLED 2026-09-14`). No Cloudflare ingress (was LAN-only via Pi-hole). Bind-mounted `infra/odysseus/data` + `infra/odysseus/logs` retained; on `odysseus.network`. | Restore quadlet name **plus its 3 sidecars below**, then `/enable-service odysseus`. |
| Odysseus ChromaDB | Disabled 2026-09-14 — Odysseus sidecar (vector store). Quadlet at `odysseus-chromadb.container.disabled`; internal-only, no route. Volume `odysseus-chromadb-data` + `odysseus.network` retained. | `mv ~/.config/containers/systemd/odysseus-chromadb.container.disabled ~/.config/containers/systemd/odysseus-chromadb.container && systemctl --user daemon-reload && systemctl --user start odysseus-chromadb`. |
| Odysseus SearXNG | Disabled 2026-09-14 — Odysseus sidecar (metasearch). Quadlet at `odysseus-searxng.container.disabled`; internal-only, no route. Pinned image + pre-rendered `infra/odysseus/searxng-data/settings.yml` retained. | `mv ~/.config/containers/systemd/odysseus-searxng.container.disabled ~/.config/containers/systemd/odysseus-searxng.container && systemctl --user daemon-reload && systemctl --user start odysseus-searxng`. |
| Odysseus ntfy | Disabled 2026-09-14 — not in use (Odysseus workspace itself already inactive). Quadlet at `odysseus-ntfy.container.disabled`; internal-only, no route. Volume `odysseus-ntfy-cache` + `odysseus.network` retained. | `mv ~/.config/containers/systemd/odysseus-ntfy.container.disabled ~/.config/containers/systemd/odysseus-ntfy.container && systemctl --user daemon-reload && systemctl --user start odysseus-ntfy`. |

## Cloudflare Tunnel Ingress

Tunnel ID: `cfb4f951-81ba-415b-9846-9273b523631d`  
Config: `/etc/cloudflared/config.yml` (sudo required)

**DNS (2026-07-08):** `*.youssefalhassan.com` is now a wildcard CNAME → `cfb4f951-81ba-415b-9846-9273b523631d.cfargotunnel.com` (proxied) in the Cloudflare dashboard, added while registering `ai.youssefalhassan.com`. New subdomains no longer need their own DNS record — only the ingress entry below. (This supersedes the per-subdomain CNAME steps noted for Hermes/Odysseus further up this table — those were needed at the time but wouldn't be going forward.) See `docs/networking.md` DNS section for details.

| Subdomain | Backend |
|-----------|---------|
| `pi5.youssefalhassan.com` | `ssh://localhost:22` |
| `vw.youssefalhassan.com` | `https://localhost:443` |
| `ha.youssefalhassan.com` | `https://localhost:443` |
| `mm.youssefalhassan.com` | `https://localhost:443` |
| `auth.youssefalhassan.com` | `https://localhost:443` |
| `proxy.youssefalhassan.com` | `https://localhost:443` |
| `jf.youssefalhassan.com` | `https://localhost:443` |
| `cloud.youssefalhassan.com` | `https://localhost:443` |
| `nefarious.youssefalhassan.com` | `https://localhost:443` |
| `memos.youssefalhassan.com` | `https://localhost:443` |
