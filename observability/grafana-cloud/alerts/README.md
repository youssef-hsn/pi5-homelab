# Suggested Alerts — Homelab (Grafana Cloud)

All queries assume the `cluster=homelab` external label set by Alloy and
the `integrations/node_exporter` job. Use the **grafanacloud-prom** datasource.

Configure these in Grafana Cloud → **Alerting → Alert rules** → New rule.
Recommended contact point: a single notification channel (email or push) so
you don't drown in noise on a one-host setup.

---

## Critical (page me)

### 1. Host down
The Pi stopped reporting metrics — Alloy crashed, Pi rebooted, or network is dead.

```promql
max(up{job="integrations/node_exporter", cluster="homelab"}) == 0
```

For: **5m** · Severity: critical

> Tip: also alert on `absent_over_time(up{job="integrations/node_exporter"}[10m])` to
> catch the case where the metric stops appearing entirely.

### 2. CPU temperature critical
Pi 5 throttles ~80 °C and shuts down at 85 °C.

```promql
max(node_hwmon_temp_celsius{cluster="homelab"}) > 82
```

For: **2m** · Severity: critical

### 3. Filesystem almost full
SD card / SSD running out — services will start failing writes.

```promql
100 * (node_filesystem_avail_bytes{cluster="homelab", fstype!~"tmpfs|overlay|squashfs"}
       / node_filesystem_size_bytes{cluster="homelab", fstype!~"tmpfs|overlay|squashfs"}) < 5
```

For: **15m** · Severity: critical

---

## Warning (look at it later)

### 4. CPU temperature warm
Early signal — fan dirty, ambient temp high, or something is hot-looping.

```promql
max(node_hwmon_temp_celsius{cluster="homelab"}) > 75
```

For: **15m** · Severity: warning

### 5. High memory pressure
Less than 10% of RAM available — next step is OOM kills or swap thrash.

```promql
100 * (node_memory_MemAvailable_bytes{cluster="homelab"}
       / node_memory_MemTotal_bytes{cluster="homelab"}) < 10
```

For: **15m** · Severity: warning

### 6. Sustained swap usage
On a Pi this kills storage lifespan and tanks performance.

```promql
100 * (1 - (node_memory_SwapFree_bytes{cluster="homelab"}
            / clamp_min(node_memory_SwapTotal_bytes{cluster="homelab"}, 1))) > 50
```

For: **30m** · Severity: warning

### 7. Disk filling — predictive
Predicts the filesystem will be full within 24h based on the last 6h trend.
Lets you act before the "almost full" page fires.

```promql
predict_linear(node_filesystem_avail_bytes{cluster="homelab", fstype!~"tmpfs|overlay|squashfs"}[6h], 24*3600) < 0
  and
node_filesystem_avail_bytes{cluster="homelab", fstype!~"tmpfs|overlay|squashfs"} > 0
```

For: **1h** · Severity: warning

### 8. High load average
Pi 5 has 4 cores — 5m load > 6 means a sustained backlog.

```promql
node_load5{cluster="homelab"}
  / count(count by (cpu) (node_cpu_seconds_total{cluster="homelab"})) > 1.5
```

For: **15m** · Severity: warning

### 9. Filesystem 85% full
Earlier warning before the critical 95% threshold.

```promql
100 * (node_filesystem_avail_bytes{cluster="homelab", fstype!~"tmpfs|overlay|squashfs"}
       / node_filesystem_size_bytes{cluster="homelab", fstype!~"tmpfs|overlay|squashfs"}) < 15
```

For: **30m** · Severity: warning

---

## Info / hygiene (optional)

### 10. Pi rebooted
Useful as a notification, not a page.

```promql
(time() - node_boot_time_seconds{cluster="homelab"}) < 300
```

For: **0m** · Severity: info

### 11. Network errors
Cable, port, or driver flakiness.

```promql
sum by (device) (rate(node_network_receive_errs_total{cluster="homelab", device!~"lo|veth.*|cni.*|podman.*"}[5m])
                 + rate(node_network_transmit_errs_total{cluster="homelab", device!~"lo|veth.*|cni.*|podman.*"}[5m])) > 1
```

For: **10m** · Severity: info

---

## Loki-based alerts

You're already using Drilldown for logs — but a couple of standing alerts pay off:

### 12. Spike in error logs from any container
Catches services that started crash-looping without you noticing.

```logql
sum by (container) (rate({job="podman"} |~ "(?i)\\b(error|panic|fatal)\\b" [5m])) > 1
```

For: **10m** · Severity: warning

### 13. systemd unit failed
Catches a quadlet service that died and didn't restart.

```logql
sum(count_over_time({job="integrations/journald"} |= "Failed with result" [5m])) > 0
```

For: **0m** · Severity: warning

---

## Notes

- All thresholds are starting points. Watch for a week and tune — alerts that fire
  when nothing is wrong train you to ignore them.
- Grafana Cloud free tier limits the number of alert rules; if you hit it, drop
  the "info" tier first.
- For `node_hwmon_temp_celsius` — if you see multiple sensors on the Pi 5 and want
  to alert only on the SoC, filter by the specific `chip` label after checking
  what's actually exposed (run `node_hwmon_temp_celsius` in Explore).
