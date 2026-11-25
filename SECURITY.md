# Security

The packages built here install an Electron desktop application (`antigravity`) system-wide under
`/usr/lib64/antigravity` and `/usr/bin/antigravity`. Installing them means trusting this repo, its
build, upstream's artifact host, and COPR.

## Reporting

Use [private vulnerability reporting](https://github.com/karanshukla/agy_fedora_unofficial/security/advisories/new).
Do not open a public issue for anything exploitable. Bugs in Antigravity itself belong upstream.

## Threat model

| Threat | Defence |
|---|---|
| Misdirected or spoofed upstream download URL | `latest-version.sh` fetches the Linux x64 update manifest over HTTPS from the upstream updater endpoint and requires the resolved artifact base URL to live under `https://storage.googleapis.com/antigravity-public/antigravity-hub/.../linux-x64/`. `make-srpm.sh` extracts `resources/app.asar` and verifies that its embedded `package.json` version matches the manifest version before building the SRPM. |
| Something other than the reviewed packaging reaching the RPM | The RPM wraps the upstream tarball with only `antigravity.spec`, `antigravity.desktop`, and `antigravity.sh` from this repo. CI builds the real SRPM on every PR and checks its contents. |
| PR that changes the spec, launcher, build scripts, or CI | The `guard` check fails any PR from someone other than the owner that touches anything except `README.md`. It runs from `main`'s copy (`pull_request_target`) and never executes PR code. Only the owner's ruleset bypass can merge a flagged PR. Because a PR could add its own workflow with a job named `guard`, the ruleset does not rely on that check alone: every PR also needs a code-owner (owner) approval, given after its last push and dismissed by a new one. |
| Leaked COPR token | The token lives in the `copr` environment, which only `main` can deploy to, so a PR or another branch cannot read it. It is written to disk with mode `600` only in the job that calls COPR, after the SRPM is built. It expires after 180 days. `copr.yml` requests `contents: write` only on `main` (never on PRs) to attach the COPR-signed RPMs and `SHA256SUMS` to GitHub Releases. |
| Compromised action | Every action is pinned to a commit SHA, only GitHub-owned actions are allowed, `actionlint` is checked against a pinned sha256, Dependabot waits 7 days, and nothing auto-merges. |
| History rewritten | Force pushes and deletion of `main` are blocked by ruleset. |

## What it does not defend against

- **Upstream shipping a malicious Antigravity release.** This packages what Google publishes to `storage.googleapis.com/antigravity-public/antigravity-hub/`; it cannot audit the closed-source binaries.
- **No detached checksum/signature on `Antigravity.tar.gz`.** Upstream's `latest-x64-linux.yml` publishes `sha512` hashes for `.AppImage` and `.deb`, not for `.tar.gz`. Integrity of the tarball relies on TLS to `storage.googleapis.com` plus the embedded `app.asar` version check.
- **COPR's build infrastructure.** COPR builds the SRPM in its own mock chroot and signs the result with this project's COPR key. `dnf` checks that key when you install.
- **The Fedora container image.** `registry.fedoraproject.org/fedora:45` is pulled over TLS by tag, not by digest.
- **A compromised owner account.**
