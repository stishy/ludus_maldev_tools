# Ansible Role: Maldev Tools (Ludus)

An Ansible Role that transforms a Windows VM into a fully equipped **malware development and analysis workstation** for use with [Ludus](https://ludus.cloud/).

- Disables Windows Defender, AMSI, and Firewall before tool installation
- Installs languages: Python 3, Go, Rust, Nim (with maldev pip packages)
- Installs compilers and build tools: MSYS2/MinGW, NASM, CMake
- Installs VS Code + Visual Studio 2022 Community (C++/C# workloads)
- Installs VS Code extensions machine-wide (visible to all users)
- Installs 23 RE/analysis tools via Chocolatey (Ghidra, IDA Free, x64dbg, PE-bear, dnSpy, DIE, UPX, Resource Hacker, PE-sieve, ExifTool, ConfuserEx, CyberChef, WinDbg, and more)
- Installs Wireshark with Npcap
- Clones 25 offensive GitHub repos to `C:\Tools\` (SysWhispers3, ScareCrow, Freeze, Donut, HellsGate, TartarusGate, BOF.NET, 12 BOF repos, and more)
- Builds cloned repos on-host: Go (ScareCrow, Freeze, Fritter), MinGW C (Fritter, COFFLoader), MSBuild (HellsGate, TartarusGate), pip (Donut)
- Compiles ThreatCheck on-host via MSBuild + NuGet
- Downloads Sliver C2 client binary
- Creates Public Desktop shortcuts for all key tools
- Deploys `Enable-Defender.ps1` / `Disable-Defender.ps1` toggle scripts to `C:\Tools\`
- Fully idempotent — safe to re-run

> [!WARNING]
> This role intentionally disables Windows security controls (Defender, AMSI, Firewall). Only use in isolated lab/range environments.

## Requirements

None.

### Ansible Collections

These collections are required on the Ansible controller:

```bash
ansible-galaxy collection install ansible.windows
ansible-galaxy collection install community.windows
ansible-galaxy collection install chocolatey.chocolatey
```

Or via `requirements.yml`:

```yaml
collections:
  - name: ansible.windows
  - name: community.windows
  - name: chocolatey.chocolatey
```

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

```yaml
# Category toggles — set any to false to skip that category
ludus_maldev_security_disable: true         # Disable Defender, AMSI, Firewall
ludus_maldev_install_utilities: true        # git, 7zip, wget, curl, notepad++
ludus_maldev_install_languages: true        # Python 3, Go, Rust, Nim
ludus_maldev_install_compilers: true        # MSYS2, NASM, CMake
ludus_maldev_install_ides: true             # VS Code + Visual Studio 2022 Community
ludus_maldev_install_vscode_extensions: true  # 19 VS Code extensions (machine-wide)
ludus_maldev_install_re_tools: true         # RE/analysis tools via Chocolatey
ludus_maldev_install_networking: true       # Wireshark
ludus_maldev_install_offensive_repos: true  # Clone 25 offensive GitHub repos + build
ludus_maldev_create_shortcuts: true         # Public Desktop shortcuts
ludus_maldev_install_c2_clients: true       # Sliver C2 client binary

# Paths
ludus_maldev_tools_dir: "C:\\Tools"         # Root directory for all tools and repos
ludus_maldev_repos_dir: "C:\\Tools"         # Repo clone directory (repos at C:\Tools\<name>)
```

## Example Ludus Range Config

```yaml
ludus:
  - vm_name: "{{ range_id }}-maldev"
    hostname: maldev
    template: win2022-server-x64-template
    vlan: 10
    ip_last_octet: 50
    ram_gb: 8
    cpus: 4
    windows:
      sysprep: true
    domain:
      fqdn: example.com
      role: member
    roles:
      - stishy.ludus_maldev_tools
```

### RE-only workstation (no offensive tools or IDEs)

```yaml
roles:
  - stishy.ludus_maldev_tools
  role_vars:
    ludus_maldev_install_languages: false
    ludus_maldev_install_compilers: false
    ludus_maldev_install_ides: false
    ludus_maldev_install_vscode_extensions: false
    ludus_maldev_install_offensive_repos: false
    ludus_maldev_install_c2_clients: false
```

### Skip security disable (already disabled or using your own method)

```yaml
roles:
  - stishy.ludus_maldev_tools
  role_vars:
    ludus_maldev_security_disable: false
```

## What Gets Installed

### Languages (via Chocolatey)
- Python 3 with pip packages: `pycryptodome`, `pefile`, `capstone`, `keystone-engine`, `requests`
- Go, Rust (rustup), Nim

### Compilers & Build Tools (via Chocolatey)
- MSYS2 / MinGW, NASM, CMake

### IDEs (via Chocolatey)
- VS Code with 19 extensions installed machine-wide to `C:\Tools\.vscode-extensions`
- Visual Studio 2022 Community with NativeDesktop + ManagedDesktop + MSBuild workloads

### RE / Analysis Tools (via Chocolatey)
PE-bear, x64dbg/x32dbg, System Informer, Process Monitor, Sysinternals Suite, OpenJDK 21, Ghidra, dnSpy, Detect It Easy (DIE), HxD, CFF Explorer (Explorer Suite), IDA Free, YARA, Windows Driver Kit 11, Windows SDK, UPX, Resource Hacker (`reshack`), PE-sieve, ExifTool, ConfuserEx, CyberChef, WinDbg

### Offensive Repos (cloned to `C:\Tools\<name>`)
SysWhispers3, NimlineWhispers3, InlineWhispers2, HellsGate, TartarusGate, Donut, ScareCrow, Freeze, SharpCollection, BOF.NET, KDU, phnt, aad\_prt\_bof, ADSyncDump-BOF, BITS-bof, bof-vs, COFFLoader, CS-Remote-OPs-BOF, CS-Situational-Awareness-BOF, eden, GhostKatz, InlineExecute-Assembly, lsawhisper-bof, sleepmask-vs, Fritter

### On-Host Builds
| Repo | Method |
|---|---|
| ScareCrow | `go build` |
| Freeze | `go build` |
| Fritter | MinGW `make -f Makefile.mingw` |
| COFFLoader | `x86_64-w64-mingw32-gcc` (64-bit) |
| HellsGate | MSBuild `/p:PlatformToolset=v143` |
| TartarusGate | MSBuild `/p:PlatformToolset=v143` |
| Donut | `pip install .` (C extension via Python) |
| ThreatCheck | NuGet restore + MSBuild (requires `netfx-4.8.1-devpack`) |

### C2 Clients
- Sliver client binary (latest GitHub release, downloaded to `C:\Tools\sliver\`)

> **Note:** Havoc C2 is Linux-only — install on your Kali box instead.

## Notes

- **Visual Studio 2022** install takes 60–90 minutes. The role uses `async: 5400` with `poll: 60`.
- **JAVA_HOME** is set automatically for Ghidra. The Ghidra shortcut uses a registry-reading wrapper script to ensure Java is always found.
- **VS Code extensions** are installed to `C:\Tools\.vscode-extensions` with `VSCODE_EXTENSIONS` set as a machine env var — works for all users (domain admin, localuser, or any future user).
- **Defender/AMSI/Firewall** can be re-enabled at any time using `C:\Tools\Enable-Defender.ps1`. Cloud-delivered protection and sample submission remain OFF to protect payloads.
- A **system reboot** after role completion is recommended for all security control changes to fully propagate.

## License

MIT

## Author Information

This role was created in 2025 by [stishy](https://github.com/stishy), for use with [Ludus](https://ludus.cloud/).
