Add a new self-hosted service to the homelab. Arguments: $ARGUMENTS

Parse the arguments as: `<service-name> <local-port> [subdomain] [image]`
- `service-name`: short slug, e.g. `gitea`
- `local-port`: port the container listens on, e.g. `3000`
- `subdomain`: optional, e.g. `git` → `git.youssefalhassan.com`; omit if LAN-only
- `image`: optional container image, e.g. `docker.io/gitea/gitea:latest`

If any required info is missing, ask before proceeding.

## Steps to perform

1. **Create config directory**: `mkdir -p ~/infra/<service-name>/`

2. **Write quadlet** at `~/.config/containers/systemd/<service-name>.container` using the template in `docs/quadlets.md`. Use `%h/infra/<service-name>/` for config mounts. Set `TZ=Asia/Beirut`, `Restart=always`.

3. **Add Traefik route** — if a subdomain was given, append to `~/infra/traefik/dynamic/services.yml`:
   - Router: `Host(\`<subdomain>.youssefalhassan.com\`)`, entryPoint `websecure`, certResolver `letsencrypt`
   - Decide with the user whether to add `authelia` middleware (default: yes for admin tools, no for public apps)
   - Service: `loadBalancer.servers[0].url: http://127.0.0.1:<port>`

4. **Add Cloudflare ingress** — if a subdomain was given, insert before the catch-all in `/etc/cloudflared/config.yml`:
   ```yaml
   - hostname: <subdomain>.youssefalhassan.com
     service: https://localhost:443
     originRequest:
       originServerName: <subdomain>.youssefalhassan.com
   ```
   Then run: `sudo systemctl restart cloudflared`

5. **Start the service**:
   ```bash
   systemctl --user daemon-reload
   systemctl --user enable --now <service-name>
   ```

6. **Verify**: `journalctl --user -u <service-name> -n 30`

7. **Update docs** — mandatory:
   - Add a row to `docs/services.md` (Active Services table and Cloudflare Tunnel Ingress table if external)
   - Update `docs/networking.md` if a new container network was created
   - Update `CLAUDE.md` if the service introduces a new pattern or dependency

Show a summary of every file changed at the end.
