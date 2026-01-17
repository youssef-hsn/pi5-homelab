# Why Podman?

This homelab uses **Podman** for containerization instead of Docker. This decision aligns with our core philosophy of resource efficiency, open source principles, and learning by doing. Here's why Podman was chosen and what benefits it brings to this setup.

## Core Philosophy Alignment

### 1. Resource Efficiency First

Podman is **daemonless** unlike Docker, it doesn't require a long-running daemon process consuming system resources. This is crucial for a Raspberry Pi 5 homelab where every megabyte of RAM matters:

- **No daemon overhead**: Docker's `dockerd` daemon runs continuously, consuming memory even when no containers are running. Podman runs containers directly via `runc`, eliminating this overhead.
- **Lower memory footprint**: Particularly important on a 8GB Pi 5 where efficient resource utilization is key to running multiple services.
- **Process-based architecture**: Containers run as regular processes under the user, making resource monitoring and management more straightforward.

### 2. Open Source by Default

Podman is fully open source (Apache 2.0) and part of the broader Red Hat ecosystem (now maintained by the community and Red Hat). While Docker CE is also open source, Docker Inc.'s commercial focus and licensing changes have created uncertainty in the open source container runtime space. Podman represents a community-driven alternative that aligns with open source principles.

### 3. Learn by Doing

Podman offers a Docker-compatible CLI, so the learning curve is minimal. If you know Docker, you can use Podman with the same commands (`podman` instead of `docker`). However, Podman also provides opportunities to learn:

- **Rootless containers by default**: Encourages understanding of Linux user namespaces and security best practices
- **Pod concept**: Introduces Kubernetes-like concepts (pods) that help prepare for orchestration tools
- **Systemd integration**: Better integration with systemd for service management, teaching modern Linux service patterns

## Key Benefits for Homelab Use

### Rootless Containers

Podman runs containers as the current user by default, not as root. This provides:

- **Enhanced security**: If a container is compromised, it doesn't have root privileges on the host
- **No sudo required**: Run containers without `sudo`, reducing the risk of accidental system modifications

### Daemonless Architecture

- **Faster startup**: No daemon to start/stop; containers launch immediately
- **Better system integration**: Containers can be managed via systemd, systemctl, and other standard Linux tools
- **Cleaner process tree**: Containers appear as normal processes, making debugging and monitoring easier

### Docker Compatibility

Podman is designed to be a drop-in replacement for Docker in many scenarios:

- **Same CLI commands**: `podman run`, `podman build`, `podman ps` work just like their Docker equivalents
- **Dockerfile compatible**: Uses the same Dockerfile format
- **Image compatibility**: Can pull and run images from Docker Hub and other registries
- **docker-compose alternative**: `podman-compose` provides similar functionality (though native `podman play kube` is preferred for Kubernetes-style workloads)

## Why Not Docker?

While Docker is excellent and widely adopted, several factors make Podman a better fit for this homelab:

1. **Resource overhead**: The Docker daemon consumes memory continuously, which matters on resource-constrained hardware
2. **Root requirement**: Docker traditionally requires root access (or Docker group membership, which is effectively root-equivalent)

## References and Learning Resources

- [Podman Documentation](https://docs.podman.io/)
- [Podman vs Docker: Key Differences](https://www.redhat.com/en/topics/containers/what-is-podman)
- [Rootless Containers Guide](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md)

---

*This documentation reflects real-world usage and decision-making in this homelab. As the setup evolves, this rationale may be updated to reflect new learnings and changes.*
