#!/bin/bash
# Build a source RPM of Antigravity from either the upstream release or a local Antigravity.tar.gz.
#
# Usage:
#   ./make-srpm.sh OUTDIR                      # fetch latest Antigravity.tar.gz from upstream
#   ./make-srpm.sh OUTDIR /path/to/tar.gz      # build from a local Antigravity.tar.gz
#   ./make-srpm.sh OUTDIR https://.../tar.gz   # build from an explicit tarball URL

set -euo pipefail

OUT=$(realpath -m "${1:?Usage: $0 OUTDIR [TARBALL_OR_URL]}")
SRC="${2:-}"
HERE=$(cd "$(dirname "$0")" && pwd)
REL=$(tr -d '[:space:]' < "$HERE/RELEASE")

[[ $REL =~ ^[0-9]+$ ]] || { echo "bad RELEASE: '$REL'" >&2; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

EXPECTED_VER=""
mkdir -p "$WORK/in"

if [[ -z "$SRC" ]]; then
    IFS=$'\t' read -r EXPECTED_VER SRC < <("$HERE/latest-version.sh" --url)
    echo "Upstream Antigravity $EXPECTED_VER: $SRC" >&2
fi

if [[ "$SRC" =~ ^https:// ]]; then
    curl -fsSL "$SRC" -o "$WORK/in/Antigravity.tar.gz"
else
    [[ -f "$SRC" ]] || { echo "tarball not found: $SRC" >&2; exit 1; }
    cp -f "$SRC" "$WORK/in/Antigravity.tar.gz"
fi

# Extract and verify the version embedded in resources/app.asar -> package.json.
tar -xzf "$WORK/in/Antigravity.tar.gz" -C "$WORK" Antigravity-x64/resources/app.asar
VER=$(python3 -I - "$WORK/Antigravity-x64/resources/app.asar" <<'EOF'
import json, struct, sys

with open(sys.argv[1], "rb") as f:
    _, header_size, _, str_len = struct.unpack("<IIII", f.read(16))
    header = json.loads(f.read(str_len).decode("utf-8"))
    info = header["files"]["package.json"]
    f.seek(8 + header_size + int(info["offset"]))
    pkg = json.loads(f.read(info["size"]).decode("utf-8"))
    print(pkg["version"])
EOF
)
[[ $VER =~ ^[0-9][0-9.]*$ ]] || { echo "unexpected app.asar version: '$VER'" >&2; exit 1; }
if [[ -n "$EXPECTED_VER" && "$VER" != "$EXPECTED_VER" ]]; then
    echo "::error::manifest version ($EXPECTED_VER) != app.asar version ($VER)" >&2
    exit 2
fi

cp -f "$HERE/antigravity.desktop" "$HERE/antigravity.sh" "$HERE/antigravity.spec" "$WORK/in/"

python3 -I - "$WORK/in/antigravity.spec" "$VER" "$REL" <<'EOF'
import re, sys

path, ver, rel = sys.argv[1:4]
s = open(path).read()
s, n1 = re.subn(r'^(Version:\s*)\S+', r'\g<1>' + ver, s, count=1, flags=re.M)
s, n2 = re.subn(r'^(Release:\s*)\S+', r'\g<1>' + rel + '%{?dist}', s, count=1, flags=re.M)
if n1 != 1 or n2 != 1:
    sys.exit("failed to update Version/Release in antigravity.spec")
open(path, "w").write(s)
EOF

mkdir -p "$OUT"
rpmbuild -bs "$WORK/in/antigravity.spec" \
    --define "_topdir $WORK/rpmbuild" \
    --define "_tmppath /tmp" \
    --define "_sourcedir $WORK/in" \
    --define "_srcrpmdir $OUT" >&2

shopt -s nullglob
srpms=("$OUT"/antigravity-"$VER"-"$REL".*.src.rpm)
[[ ${#srpms[@]} -eq 1 ]] || { echo "expected 1 SRPM in $OUT, got ${#srpms[@]}" >&2; exit 1; }
echo "${srpms[0]}"
