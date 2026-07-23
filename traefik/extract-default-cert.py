#!/usr/bin/env python3
"""Extract the *.youssefalhassan.com wildcard from Traefik's acme.json into PEM
files that the Traefik file provider serves as the store's default certificate.

Why: on a Traefik restart there is a brief window after :443 reopens but before
certs load from acme.json, during which Traefik serves its built-in self-signed
"TRAEFIK DEFAULT CERT". On the LAN direct-to-Traefik path a browser holding the
zone's HSTS pin then gets a sticky, unbypassable cert error. A static
defaultCertificate is delivered by the file provider (independent of acme.json),
so it is present during that window and the self-signed cert is never served.

Traefik keeps the wildcard itself issued and renewed (defaultGeneratedCert in
dynamic/tls.yml); this script just mirrors it to PEM. Run on a daily timer so a
renewed wildcard is picked up. On change it touches dynamic/tls.yml to trigger a
hot-reload (no restart, no downtime).
"""
import base64
import json
import os
import sys

HOME = os.environ.get("HOME", os.path.expanduser("~"))
ACME = os.path.join(HOME, "infra/traefik/acme/acme.json")
OUT = os.path.join(HOME, "infra/traefik/certs")
RELOAD_TRIGGER = os.path.join(HOME, "infra/traefik/dynamic/tls.yml")
MAIN = "youssefalhassan.com"  # wildcard cert's domain.main


def find_wildcard(acme):
    for resolver in acme.values():
        for cert in resolver.get("Certificates") or []:
            if cert.get("domain", {}).get("main") == MAIN:
                return cert
    return None


def write_if_changed(path, data, mode):
    if os.path.exists(path):
        with open(path, "rb") as f:
            if f.read() == data:
                return False
    tmp = path + ".tmp"
    with open(tmp, "wb") as f:
        f.write(data)
    os.chmod(tmp, mode)
    os.replace(tmp, path)
    return True


def main():
    with open(ACME) as f:
        acme = json.load(f)
    cert = find_wildcard(acme)
    if not cert:
        print(f"ERROR: wildcard cert (main={MAIN}) not found in {ACME}", file=sys.stderr)
        return 1
    crt = base64.b64decode(cert["certificate"])
    key = base64.b64decode(cert["key"])
    os.makedirs(OUT, exist_ok=True)
    changed = False
    changed |= write_if_changed(os.path.join(OUT, "default.crt"), crt, 0o644)
    changed |= write_if_changed(os.path.join(OUT, "default.key"), key, 0o600)
    if changed:
        os.utime(RELOAD_TRIGGER, None)  # bump mtime -> Traefik file provider reloads
        print("default cert updated; triggered Traefik reload")
    else:
        print("default cert unchanged")
    return 0


if __name__ == "__main__":
    sys.exit(main())
