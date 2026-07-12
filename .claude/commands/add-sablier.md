Add Sablier sleep/wake middleware to an existing service. Arguments: $ARGUMENTS

Parse argument as: `<service-name>`

Sablier puts low-traffic services to sleep and wakes them on first request. Read the existing Sablier middleware blocks in `~/infra/traefik/dynamic/sablier.yml` to match the pattern.

## Steps to perform

1. **Read** `~/infra/traefik/dynamic/sablier.yml` to understand existing middleware naming convention.

2. **Add a new Sablier middleware** for this service to `sablier.yml` following the same pattern as existing entries.

3. **Add the middleware** to the service's router in `~/infra/traefik/dynamic/services.yml`:
   ```yaml
   middlewares: [sablier-<service-name>]
   # or alongside authelia:
   middlewares: [authelia, sablier-<service-name>]
   ```

4. Traefik hot-reloads — verify no errors: `journalctl --user -u traefik -n 20`

5. **Update docs** — mandatory:
   - Update the service's Notes column in `docs/services.md` to note "Sablier sleep".

Show a summary of every file changed at the end.
