Reconcile all documentation with current live state. No arguments needed.

This command audits the actual system state and brings docs up to date. Run it after any manual infra changes.

## Steps to perform

1. **Audit running services**:
   ```bash
   systemctl --user list-units --type=service --state=active
   systemctl --user list-units --type=service --state=failed
   ```

2. **Audit quadlet files**:
   ```bash
   ls ~/.config/containers/systemd/
   ```

3. **Read current Traefik routes**: `~/infra/traefik/dynamic/services.yml`

4. **Read current Cloudflare config**: `/etc/cloudflared/config.yml`

5. **Compare against `docs/services.md`** — identify:
   - Services running but not documented → add them
   - Services documented as active but not running → investigate, update status
   - Routes in Traefik but not in Cloudflare (or vice versa) → flag to user

6. **Update these files as needed**:
   - `docs/services.md` — service registry, ports, subdomains, status
   - `docs/networking.md` — Traefik routes, Cloudflare tunnel table
   - `CLAUDE.md` — if any patterns or conventions changed

7. **Report** a diff summary: what was stale, what was updated.
