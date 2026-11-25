#!/bin/bash
# Print the latest Linux x64 Antigravity version (or VERSION<tab>TARBALL_URL with --url)
# from the official upstream auto-updater manifest.

set -euo pipefail

MANIFEST_URL="https://antigravity-hub-auto-updater-974169037036.us-central1.run.app/manifest/latest-x64-linux.yml"
manifest=$(curl -fsSL "$MANIFEST_URL")

python3 -I - "$manifest" "${1:-}" <<'EOF'
import re, sys

text, mode = sys.argv[1], sys.argv[2]
m_ver = re.search(r'^version:\s*([0-9][0-9.]*)\s*$', text, re.M)
if not m_ver:
    sys.exit("could not parse version from manifest")
ver = m_ver.group(1)

m_url = re.search(
    r'^\s*-\s*url:\s*(https://storage\.googleapis\.com/antigravity-public/antigravity-hub/[^\s]+/linux-x64/)[^\s/]+\s*$',
    text,
    re.M,
)
if not m_url:
    sys.exit("could not parse artifact base URL from manifest")
tar_url = m_url.group(1) + "Antigravity.tar.gz"

if mode == "--url":
    print(f"{ver}\t{tar_url}")
elif mode == "":
    print(ver)
else:
    sys.exit(f"unknown argument: {mode}")
EOF
