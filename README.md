# agy_fedora_unofficial

Unofficial Fedora RPM packaging and COPR automation for the **Antigravity** Electron desktop application (`x86_64`, not the IDE). Comes from the Tarball for Linux available here: https://antigravity.google/download#antigravity-2

COPR repo: <https://copr.fedorainfracloud.org/coprs/karanshukla/agy_fedora_unofficial/>

## Install

```bash
sudo dnf copr enable karanshukla/agy_fedora_unofficial
sudo dnf install antigravity
```

Alternatively, download the COPR-signed `.x86_64.rpm` directly from [GitHub Releases](https://github.com/karanshukla/agy_fedora_unofficial/releases) and install it with `sudo dnf install ./antigravity-*.x86_64.rpm`.

To pass extra Electron/Chromium flags (in addition to the default `--ozone-platform-hint=auto`), add one flag per line to `~/.config/antigravity-flags.conf`.

## How it updates

`.github/workflows/copr.yml` runs every 6 hours:

1. `latest-version.sh` queries upstream's Linux x64 update manifest (`latest-x64-linux.yml`) for the latest version and GCS artifact URL.
2. If COPR (`karanshukla/agy_fedora_unofficial`) has no build for `<version>-<RELEASE>` yet, `make-srpm.sh` downloads `Antigravity.tar.gz`, verifies the version embedded in `resources/app.asar` matches, updates `antigravity.spec`, and builds the `.src.rpm`.
3. `copr-cli` submits the SRPM to COPR for all enabled chroots (`fedora-44-x86_64`, `fedora-45-x86_64`).

## Local builds

Build an SRPM (for COPR upload) from a local tarball:

```bash
./make-srpm.sh out ~/Downloads/Antigravity.tar.gz
```

Or build both the SRPM and installable `.x86_64.rpm` locally:

```bash
./build.sh ~/Downloads/Antigravity.tar.gz
sudo dnf install ./rpmbuild/RPMS/x86_64/antigravity-*.x86_64.rpm
```

## Maintenance

- **Packaging changed (same upstream version):** bump `RELEASE` (`1` -> `2`) and push to `main`.
- **COPR token:** contact the maintainer Karan Shukla
  ```

See [SECURITY.md](SECURITY.md) for what is checked and what is trusted.
