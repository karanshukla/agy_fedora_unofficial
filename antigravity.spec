%global debug_package %{nil}
%global _build_id_links none
%global _binary_payload w6.zstdio
%global __strip /bin/true
%global __brp_check_rpaths %{nil}
%global __brp_mangle_shebangs_exclude_from ^%{_libdir}/%{name}/.*$

# Do not advertise bundled Electron/Chromium shared libraries as system Provides
%global __provides_exclude_from ^%{_libdir}/%{name}/.*$
# Do not require bundled libraries from external RPM packages
%global __requires_exclude ^(libffmpeg\\.so|libvk_swiftshader\\.so|libvulkan\\.so).*$

Name:           antigravity
Version:        2.35.1
Release:        1%{?dist}
Summary:        Antigravity - Agentic Desktop Application
License:        LicenseRef-Proprietary
URL:            https://antigravity.google
ExclusiveArch:  x86_64

# For COPR SCM builds with a public release URL, replace Source0 with the direct URL
Source0:        Antigravity.tar.gz
Source1:        antigravity.desktop
Source2:        antigravity.sh

BuildRequires:  desktop-file-utils
BuildRequires:  python3

Requires:       hicolor-icon-theme
Requires:       libXScrnSaver
Requires:       libXtst
Requires:       libnotify
Requires:       xdg-utils

%description
Antigravity is an agentic desktop application built with Electron.
This is an unofficial Fedora RPM wrapper around the upstream Linux x64 archive.

%prep
%setup -q -n Antigravity-x64

%build
# Extract the 512x512 application icon directly from resources/app.asar
python3 - <<'EOF'
import json, struct

with open("resources/app.asar", "rb") as f:
    _, header_size, _, str_len = struct.unpack("<IIII", f.read(16))
    header = json.loads(f.read(str_len).decode("utf-8"))
    info = header["files"]["icon.png"]
    f.seek(8 + header_size + int(info["offset"]))
    with open("antigravity.png", "wb") as out:
        out.write(f.read(info["size"]))
EOF

%install
# Install application payload under %%{_libdir}/antigravity
install -dm0755 %{buildroot}%{_libdir}/%{name}
cp -a ./* %{buildroot}%{_libdir}/%{name}/
rm -f %{buildroot}%{_libdir}/%{name}/antigravity.png

# Install launcher wrapper
install -Dm0755 %{SOURCE2} %{buildroot}%{_bindir}/%{name}
sed -i 's|@LIBDIR@|%{_libdir}|g' %{buildroot}%{_bindir}/%{name}

# Install desktop entry
desktop-file-install \
    --dir=%{buildroot}%{_datadir}/applications \
    %{SOURCE1}

# Install application icon
install -Dm0644 antigravity.png \
    %{buildroot}%{_datadir}/icons/hicolor/512x512/apps/%{name}.png

%check
desktop-file-validate %{buildroot}%{_datadir}/applications/%{name}.desktop

%files
%license LICENSE.electron.txt LICENSES.chromium.html
%{_bindir}/%{name}
%{_libdir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/512x512/apps/%{name}.png

%changelog
* Wed Nov 25 2026 Karan Shukla <karzshukla@gmail.com> - 2.35.1-1
- Initial unofficial Fedora RPM package for Antigravity 2.35.1
