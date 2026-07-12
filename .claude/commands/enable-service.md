Re-enable a previously disabled homelab service. Arguments: $ARGUMENTS

Parse the argument as: `<service-name>`

Read `docs/services.md` Disabled Services table to confirm it's there and retrieve its port/subdomain. If not found, ask the user to clarify.

## Steps to perform

1. **Uncomment Traefik route** — if the service had a subdomain, remove the `# DISABLED` comment block in `~/infra/traefik/dynamic/services.yml` and restore the router and service entries.

2. **Uncomment Cloudflare ingress** — if external, restore the entry in `/etc/cloudflared/config.yml`, then:
   ```bash
   sudo systemctl restart cloudflared
   ```

3. **Start and enable**:
   ```bash
   systemctl --user daemon-reload
   systemctl --user enable --now <service-name>
   ```

4. **Verify**: `journalctl --user -u <service-name> -n 30`

5. **Update docs** — mandatory:
   - Move service row back from "Disabled Services" to "Active Services" in `docs/services.md`.

Show a summary of every file changed at the end.
