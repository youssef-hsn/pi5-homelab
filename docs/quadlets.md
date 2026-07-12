# Quadlet Patterns

## Location

```
~/.config/containers/systemd/
├── {service}.container
├── {service}.network     # optional
└── {service}.volume      # optional
```

## Minimal Container Template

```ini
[Unit]
Description={Service Name}
After=network-online.target

[Container]
ContainerName={service}
Image=docker.io/library/{image}:{tag}
Network={network}.network          # or "host" for host-network
Volume=%h/infra/{service}/config:/config:ro,Z
Environment=TZ=Asia/Beirut

[Service]
TimeoutStartSec=60
Restart=always
RestartSec=5s

[Install]
WantedBy=default.target
```

## With Dependency (e.g. needs postgres)

```ini
[Unit]
After=postgres.service
Requires=postgres.service
```

## Network File Template

```ini
[Network]
NetworkName={service}
```

## Volume Mount Flags

| Flag | Meaning |
|------|---------|
| `:ro` | Read-only |
| `:Z` | SELinux relabel (required for Podman) |
| `:ro,Z` | Read-only + relabel (standard for configs) |

## Lifecycle Commands

```bash
# After creating or editing a quadlet
systemctl --user daemon-reload

# Start / stop / restart
systemctl --user start {service}
systemctl --user stop {service}
systemctl --user restart {service}

# Enable autostart at login
systemctl --user enable {service}

# Disable (stop + no autostart)
systemctl --user disable --now {service}

# Logs
journalctl --user -u {service} -f
```

## Notes

- Use `%h` in quadlet files instead of `/home/youssef` — it resolves to the user home.
- Podman pulls images on first start; `podman pull` beforehand to pre-cache.
- rootless Podman: no `sudo`, services live in user slice.
