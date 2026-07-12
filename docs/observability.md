# Observability Stack

Stack path: `/home/youssef/infra/observability/`  
Network: `observability` bridge

## Components

| Component | Port | Role | Retention |
|-----------|------|------|-----------|
| Alloy | internal | Agent: scrapes metrics + ships logs | — |
| Prometheus | 127.0.0.1:9090 | Metrics store (remote_write receiver) | 15 days |
| Loki | 127.0.0.1:3100 | Log store (tsdb backend) | 7 days |
| Grafana | 192.168.0.69:3000 | Dashboards (Prometheus + Loki datasources auto-provisioned) | — |

External: `grafana.youssefalhassan.com` (Authelia protected)

## Alloy Agent

- Scrapes: node_exporter metrics via `/proc`, `/sys`, host `/` mounts
- Ships logs: journald → Loki
- Requires GID 999 (`systemd-journal`) for journal access

See [`metrics.md`](metrics.md) for the full inventory of metrics Alloy collects.

## Adding a New Scrape Target

Edit `~/infra/observability/alloy/config.alloy` and add a `prometheus.scrape` block, then:
```bash
systemctl --user restart alloy
```

## Grafana Datasources

Auto-provisioned via `~/infra/observability/grafana/provisioning/datasources/`.  
Prometheus URL: `http://prometheus:9090`  
Loki URL: `http://loki:3100`
