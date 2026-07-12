Tail or search logs for a service. Arguments: $ARGUMENTS

Parse arguments as: `<service-name> [--lines=50] [--grep=pattern]`

```bash
# Live tail
journalctl --user -u <service-name> -f -n <lines>

# With grep
journalctl --user -u <service-name> -n <lines> | grep "<pattern>"
```

For system-level services (cloudflared, nginx):
```bash
sudo journalctl -u <service-name> -f -n <lines>
```

For Nefarious (docker-compose stack):
```bash
cd ~/infra/nefarious && docker compose logs --tail=<lines> -f
```

If the service name is ambiguous or not found, list available services first and ask for clarification.

This is a read-only command — do NOT modify any files.
