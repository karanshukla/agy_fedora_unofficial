#!/usr/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARBALL="${1:-$HOME/Downloads/Antigravity.tar.gz}"
TOPDIR="$SCRIPT_DIR/rpmbuild"

if [[ ! -f "$TARBALL" ]]; then
    echo "Error: tarball not found at: $TARBALL" >&2
    echo "Usage: $0 [/path/to/Antigravity.tar.gz]" >&2
    exit 1
fi

mkdir -p "$TOPDIR"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

cp -f "$TARBALL" "$TOPDIR/SOURCES/Antigravity.tar.gz"
cp -f "$SCRIPT_DIR/antigravity.desktop" "$TOPDIR/SOURCES/"
cp -f "$SCRIPT_DIR/antigravity.sh" "$TOPDIR/SOURCES/"
cp -f "$SCRIPT_DIR/antigravity.spec" "$TOPDIR/SPECS/"

echo "==> Building SRPM and RPM in $TOPDIR ..."
rpmbuild --define "_topdir $TOPDIR" --define "_tmppath /tmp" -ba "$TOPDIR/SPECS/antigravity.spec"

echo ""
echo "==> Build complete:"
ls -lh "$TOPDIR"/SRPMS/*.src.rpm "$TOPDIR"/RPMS/x86_64/*.rpm
