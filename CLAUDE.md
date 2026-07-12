# Homelab Infrastructure — Claude Context

Raspberry Pi 5 (ARM64) homelab. Rootless Podman with systemd quadlets. Domain: `youssefalhassan.com`.

## Quick Reference

| What | Where |
|------|-------|
| Quadlet files | `~/.config/containers/systemd/*.{container,network,volume}` |
| Service configs | `~/infra/{service}/` |
| Traefik dynamic routes | `~/infra/traefik/dynamic/services.yml` |
| Cloudflare tunnel config | `/etc/cloudflared/config.yml` (requires sudo) |
| Traefik static config | `~/infra/traefik/traefik.yml` |
| Docs | `~/infra/docs/` |

## Rules — Always Follow

- **Rootless Podman only.** No Docker, no root containers.
- **Quadlets in `~/.config/containers/systemd/`**, configs in `~/infra/{service}/`.
- **Use `%h`** in quadlet paths, never hardcoded `/home/youssef`.
- **Volume mounts**: use `:ro,Z` for config, `:Z` for writable data.
- **After any infra change**: update `docs/services.md`, relevant `docs/` pages, and any affected slash commands in `.claude/commands/`.
- **Reload quadlets**: `systemctl --user daemon-reload && systemctl --user restart <name>`.
- **Cloudflare tunnel**: every external subdomain needs an ingress entry in `/etc/cloudflared/config.yml` pointing to `https://localhost:443` (Traefik terminates TLS). DNS is a wildcard CNAME (`*.youssefalhassan.com` → the tunnel, set in the Cloudflare dashboard) — no per-subdomain DNS record needed, just the ingress entry. See `docs/networking.md`.
- **Traefik routes**: add router + service to `~/infra/traefik/dynamic/services.yml`; Traefik hot-reloads automatically.

## Services Overview

See `docs/services.md` for the full registry with ports, status, and URLs.

## Adding a New Service — Checklist

1. Create `~/infra/{service}/` with config files
2. Write `~/.config/containers/systemd/{service}.container`
3. Add Traefik router + service to `~/infra/traefik/dynamic/services.yml`
4. Add Cloudflare ingress entry to `/etc/cloudflared/config.yml`
5. `systemctl --user daemon-reload && systemctl --user start {service}`
6. Update `docs/services.md` and `docs/networking.md`

Use `/add-service` to do this with Claude.

## Disabling a Service — Checklist

1. `systemctl --user stop {service} && systemctl --user disable {service}`
2. Remove or comment Traefik route from `services.yml`
3. Remove Cloudflare ingress entry (if external)
4. Update `docs/services.md` status

Use `/disable-service` to do this with Claude.
