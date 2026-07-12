Show the current status of all homelab services. No arguments needed.

Run the following and present a clean summary table:

```bash
# All user quadlets
systemctl --user list-units --type=service --all | grep -E '(traefik|authelia|vaultwarden|home-assistant|monetr|jellyfin|postgres|alloy|prometheus|loki|grafana|pihole|syncthing)'

# Quick health check per service
for svc in traefik authelia home-assistant monetr jellyfin postgres alloy prometheus loki grafana; do
  status=$(systemctl --user is-active ${svc} 2>/dev/null || echo "not-found")
  echo "${svc}: ${status}"
done
```

Also check:
```bash
sudo systemctl is-active cloudflared
sudo systemctl is-active nginx
```

Present results as a markdown table: Service | Status | Notes. Flag any `failed` or `inactive` services prominently. Cross-reference with `docs/services.md` to catch any undocumented services.

Do NOT update any files — this is a read-only status check.
