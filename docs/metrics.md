# Metrics Collected by Alloy

Source of truth: `~/infra/observability/alloy/config.alloy`.

Alloy currently runs **one** metrics source: `prometheus.exporter.unix` — the
built-in node_exporter — scraped every 60s and remote-written to Grafana Cloud
Prometheus (`job=integrations/node_exporter`). Every series carries the external
labels `cluster=homelab`, `host=<HOSTNAME_LABEL>`, `instance=<HOSTNAME_LABEL>`.

No other scrape targets are configured (no cAdvisor, no blackbox, no service-level
exporters). The ~261 series visible in Drilldown is the default set of
node_exporter collectors filtered down to what's actually present on a Raspberry
Pi 5 running rootless Podman.

## What gets collected, by collector

The exporter runs with default collectors enabled. Below is the per-collector
breakdown — categories that emit no data on a Pi (mdadm, zfs, infiniband,
fibrechannel, bcache, btrfs, nvme, ipvs, tapestats, rapl, edac, bonding) are
omitted.

### CPU & scheduling
- `node_cpu_seconds_total{cpu,mode}` — per-CPU time in user/system/idle/iowait/irq/softirq/steal/nice
- `node_cpu_guest_seconds_total`
- `node_cpu_frequency_hertz`, `node_cpu_scaling_frequency_hertz{,min,max}`, `node_cpu_scaling_governor`
- `node_schedstat_*` — scheduler run/wait time per CPU
- `node_load1`, `node_load5`, `node_load15`
- `node_intr_total`, `node_context_switches_total`, `node_forks_total`, `node_procs_running`, `node_procs_blocked`
- `node_boot_time_seconds`, `node_time_seconds`, `node_time_zone_offset_seconds`
- `node_timex_*` — NTP/clock sync state, offset, frequency, jitter

### Memory
- `node_memory_MemTotal_bytes`, `MemFree_bytes`, `MemAvailable_bytes`
- `node_memory_Buffers_bytes`, `Cached_bytes`, `SReclaimable_bytes`, `Slab_bytes`
- `node_memory_Active_bytes`, `Inactive_bytes` (+ `_anon` / `_file` variants)
- `node_memory_SwapTotal_bytes`, `SwapFree_bytes`, `SwapCached_bytes`
- `node_memory_Dirty_bytes`, `Writeback_bytes`, `AnonPages_bytes`, `Mapped_bytes`, `Shmem_bytes`
- `node_memory_PageTables_bytes`, `KernelStack_bytes`, `VmallocUsed_bytes`
- `node_memory_HardwareCorrupted_bytes`
- `node_vmstat_pgfault`, `pgmajfault`, `pgpgin`, `pgpgout`, `pswpin`, `pswpout`, `oom_kill`

### Filesystem
Scope is restricted by `fs_types_exclude` / `mount_points_exclude` to skip
pseudo-filesystems and Podman/Docker overlays — so you see real disks and bind
mounts only.

- `node_filesystem_size_bytes`, `_avail_bytes`, `_free_bytes`
- `node_filesystem_files`, `_files_free`
- `node_filesystem_readonly`, `_device_error`
- Labels: `device`, `fstype`, `mountpoint`

### Disk I/O (diskstats)
- `node_disk_reads_completed_total`, `_writes_completed_total`
- `node_disk_read_bytes_total`, `_written_bytes_total`
- `node_disk_read_time_seconds_total`, `_write_time_seconds_total`
- `node_disk_io_time_seconds_total`, `_io_time_weighted_seconds_total`
- `node_disk_io_now`
- `node_disk_discards_completed_total`, `_discarded_sectors_total`, `_discard_time_seconds_total`
- `node_disk_flush_requests_total`, `_flush_requests_time_seconds_total`

### Network (netdev / netclass / netstat / sockstat)
Virtual interfaces (`veth*`, `cni*`, `podman*`, `docker*`, `br-*`, calico/flannel)
are excluded so only the real NIC(s) on the Pi are kept.

- `node_network_receive_bytes_total`, `_transmit_bytes_total`
- `node_network_receive_packets_total`, `_transmit_packets_total`
- `node_network_receive_errs_total`, `_transmit_errs_total`
- `node_network_receive_drop_total`, `_transmit_drop_total`
- `node_network_receive_multicast_total`, `_transmit_carrier_total`, `_transmit_colls_total`
- `node_network_mtu_bytes`, `_speed_bytes`, `_up`, `_carrier`, `_carrier_changes_total`
- `node_network_address_assign_type`, `_protocol_type`, `_iface_id`, `_info`
- `node_netstat_*` — kernel TCP/UDP/IP counters (TcpExt, IpExt, Udp, Icmp)
- `node_sockstat_TCP_inuse`, `_orphan`, `_tw`, `_alloc`, `_mem`, `UDP_inuse`, `FRAG_*`, `sockets_used`
- `node_softnet_processed_total`, `_dropped_total`, `_times_squeezed_total`
- `node_arp_entries`
- `node_nf_conntrack_entries`, `_entries_limit`

### Pressure stall info (PSI)
- `node_pressure_cpu_waiting_seconds_total`
- `node_pressure_memory_waiting_seconds_total`, `_stalled_seconds_total`
- `node_pressure_io_waiting_seconds_total`, `_stalled_seconds_total`

### Hardware sensors (Pi 5 thermal & power)
- `node_hwmon_temp_celsius{chip,sensor}` — SoC temps
- `node_hwmon_temp_max_celsius`, `_crit_celsius`
- `node_thermal_zone_temp`
- `node_cooling_device_cur_state`, `_max_state`
- `node_power_supply_*` — present if USB-PD / UPS HAT exposes one

### File handles & entropy
- `node_filefd_allocated`, `_maximum`
- `node_entropy_available_bits`, `_pool_size_bits`

### Systemd / OS metadata
- `node_os_info`, `node_uname_info`, `node_dmi_info`
- `node_selinux_enabled`

### Exporter self-metrics
- `node_scrape_collector_duration_seconds{collector}`
- `node_scrape_collector_success{collector}`
- `node_exporter_build_info`

### Alloy itself (emitted by the agent process, scraped by Grafana Cloud)
- `up`, `scrape_duration_seconds`, `scrape_samples_scraped`, `scrape_samples_post_metric_relabeling`, `scrape_series_added`

## What is **not** collected

- **Container metrics** — no cAdvisor, no Podman stats exporter. CPU/RAM per
  container is invisible. (Use `podman stats` ad-hoc, or add cAdvisor if needed.)
- **App-level metrics** — services that expose `/metrics` (Traefik, Authelia,
  Grafana, etc.) are **not** scraped. Add a `prometheus.scrape` block to pull them.
- **Blackbox probes** — no HTTP/TCP/ICMP synthetic checks.
- **GPU / VideoCore** — Pi VC6 has no exporter wired up.

## Logs (for completeness — not metrics)

Two `loki.source.journal` pipelines ship to Grafana Cloud Loki:

| Pipeline | Filter | Labels |
|---|---|---|
| `journald` | host journal, drops entries with `__journal_container_name` | `job=integrations/journald`, `host`, `unit`, `level`, `transport` |
| `podman` | `_COMM=conmon` (one entry per container line) | `job=podman`, `host`, `container`, `service_name`, `container_id`, `image`, `level` |

## Changing what's collected

1. Edit `~/infra/observability/alloy/config.alloy`.
2. To **add** an app exporter, drop in `prometheus.scrape "<name>" { targets = [...], forward_to = [prometheus.remote_write.gc.receiver] }`.
3. To **disable** a node_exporter collector, add `disable_collectors = ["<name>"]` to the `prometheus.exporter.unix "node"` block.
4. `systemctl --user restart alloy` and confirm with `journalctl --user -u alloy -n 50`.
