Disable a running homelab service. Arguments: $ARGUMENTS

Parse the argument as: `<service-name>`

Read `docs/services.md` to confirm the service exists and note its subdomain. If the service is not found, list active services and ask for clarification.

## Steps to perform

1. **Stop and disable**:
   ```bash
   systemctl --user stop <service-name>
   systemctl --user disable <service-name>
   ```

2. **Remove Traefik route** — if the service has a subdomain, comment out (do NOT delete) its router and service blocks in `~/infra/traefik/dynamic/services.yml`. Add a comment: `# DISABLED <date>`.

3. **Remove Cloudflare ingress** — if the service has an external subdomain, comment out its entry in `/etc/cloudflared/config.yml`, then:
   ```bash
   sudo systemctl restart cloudflared
   ```

4. **Update docs** — mandatory:
   - Move the service row from "Active Services" to "Disabled Services" in `docs/services.md`. Record the date and reason.
   - Note how to re-enable in the Disabled table (use `/enable-service <name>`).

Do NOT delete the quadlet file or config directory — preserve everything for easy re-enablement.

Show a summary of every file changed at the end.
