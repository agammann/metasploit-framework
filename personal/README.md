# Personal Metasploit toolkit for Windows

This folder adds a Windows launch setup to the
[agammann Metasploit Framework fork](https://github.com/agammann/metasploit-framework).
It runs the pinned official Metasploit Framework 6.5.5 image with PostgreSQL in
Docker Desktop, adds a command-line toolbox, and opens installed Windows desktop
companions. The console in that image identifies itself as `6.5.5-dev`.
Meterpreter payloads are included in Framework. Starting the toolkit does not
choose a target or start a scan, exploit, listener, or Meterpreter session.

Use these tools only on systems you own or have explicit permission to test.

## Quick start

Install [Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/)
with Linux containers and [Git for Windows](https://git-scm.com/install/windows).
In PowerShell, clone just this setup from the public fork:

```powershell
git clone --depth 1 --filter=blob:none --sparse https://github.com/agammann/metasploit-framework.git
Set-Location metasploit-framework
git sparse-checkout set personal
```

Open `personal/` in File Explorer and double-click **`Launch-Metasploit.cmd`**.
On first launch it creates a private local database password, builds the image,
starts PostgreSQL, opens the Toolbox window, and opens `msfconsole`. It starts
Docker Desktop if needed. The initial build needs an internet connection and
can take several minutes. Wireshark, Burp Suite, and Rust CVE Sniffer open only
when installed.

When the Metasploit prompt appears, use these read-only checks:

```text
version
db_status
workspace
```

`db_status` should report a PostgreSQL connection, and `workspace` should mark
`personal` as current. Double-click **`Stop-Metasploit.cmd`** when finished. It
stops the Metasploit, Toolbox, and database containers while keeping their
data. Close the separate Windows desktop apps yourself when finished.

### What the buttons do

| Button | Result |
| --- | --- |
| `Launch-Metasploit.cmd` | Checks Docker and the host port, builds or reuses the pinned image, starts the database, opens enabled installed companions, and opens one Metasploit console. A second click while that console runs opens missing companions without creating another console. |
| `Toolbox.cmd` | Opens a shell in the toolkit image for the bundled command-line tools. Launch Metasploit once first so the image exists. |
| `Stop-Metasploit.cmd` | Stops the Metasploit console, Toolbox, and database containers. Docker volumes and local files remain. It does not close Windows desktop apps. |
| `Install-Desktop-Companions.cmd` | Requires Windows Package Manager (`winget`) to install Wireshark and the unified Burp Suite desktop app. Review installer and license prompts; select Community Edition in Burp unless you have a Professional license. Wireshark capture also needs Npcap. |
| `Install-Rust-Cve-Sniffer.cmd` | Downloads the pinned Windows x64 portable [Rust CVE Sniffer v0.5.0 release](https://github.com/agammann/rust-cve-sniffer/releases/tag/v0.5.0), checks the published archive SHA-256 and bundled binary checksums, and opens its desktop scanner. |
| `Open-Rust-Cve-Sniffer.cmd` | Opens that portable desktop scanner again after installation. |

[Rust CVE Sniffer](https://github.com/agammann/rust-cve-sniffer), created and
maintained by `agammann`, audits dependencies in a local Rust project or `Cargo.lock`.
It is a separate Windows application; it neither scans a network host nor
imports findings into Metasploit. Its portable release includes `cargo-audit`
and does not require a local Rust or Cargo installation. It installs under the
ignored `personal/tools/` directory and does not change the Docker image. The
v0.5.0 Windows executable is unsigned; review any Windows publisher warning
against the linked release before opening it.

## Tools and their roles

The pinned container provides Framework and the command-line tools below. The
Toolbox opens an idle shell; each tool runs only when you invoke it. Rust CVE
Sniffer is the optional Windows desktop companion described above.

| Tool | Purpose and how it fits |
| --- | --- |
| Metasploit Framework and Meterpreter | Framework is the console for modules, workspaces, and results. Meterpreter is a payload family already in the pinned image, available for tests you explicitly configure. |
| Nmap | Identifies hosts, open ports, and services. Run `nmap` in the Toolbox, or `db_nmap` in Metasploit to save authorized results in its database. |
| sqlmap | Tests web requests for SQL injection. Run `sqlmap` in the Toolbox; the Metasploit sqlmap plugin additionally needs a separately configured sqlmap API service. |
| John the Ripper | Audits password hashes offline. Run `john` in the Toolbox and keep input/output files under `/workspace` when you want them to persist. |
| THC-Hydra | Performs authorized login checks against network services. Run `hydra` in the Toolbox only with a defined test target and credentials. |
| TShark | Reads and filters packet-capture files under `/workspace`. Windows host capture requires Wireshark and Npcap outside Docker. |
| Nikto | Checks web-server configuration and known issues. Run `nikto` in the Toolbox against an authorized lab web server. |
| Aircrack-ng | Analyzes existing wireless capture files under `/workspace`. Docker Desktop does not provide live monitor-mode adapter access here. |
| Volatility 3 | Analyzes memory images with the `vol` command in the Toolbox. |
| Sleuth Kit | Analyzes disk images using Toolbox commands such as `fls` and `mmls`. |
| Rust CVE Sniffer | Optional Windows desktop app for known Rust dependency advisories. Install it separately; it does not add a Metasploit module or database feed. |

To verify that Meterpreter is present without starting a session, run this in
PowerShell after the first launch:

```powershell
docker run --rm personal-metasploit:6.5.5 ./msfvenom -l payloads |
  Select-String -Pattern 'meterpreter'
```

The pinned image includes `windows/x64/meterpreter/reverse_tcp` and
`linux/x64/meterpreter/reverse_tcp`, among other variants. The
[Metasploit payload guide](https://docs.metasploit.com/docs/using-metasploit/basics/how-payloads-work.html)
explains the payload types. Metasploit's `personal-startup.rc` selects the
`personal` database workspace at launch. You may create another workspace with
`workspace -a lab`; `hosts` and `services` display imported results after an
authorized `db_nmap` run.

## Other tools from your list

The container concentrates on tools that work reliably as Linux command-line
programs with shared files. Desktop GUIs, hardware-dependent capture, separate
services, and licensed products have different installation or runtime needs.
The launch button opens Burp Suite and Wireshark when installed, but does not
install them or start the other services below:

| Tool | Practical setup |
| --- | --- |
| Burp Suite | Install the [Windows desktop app](https://portswigger.net/burp/downloads) and choose Community Edition unless you have a Professional license. You can place exported requests or logs in `workspace/` for use with sqlmap. |
| Hashcat | Install [Hashcat for Windows](https://hashcat.net/hashcat/) for GPU use. Docker Desktop GPU support on Windows has specific [hardware and WSL2 requirements](https://docs.docker.com/desktop/features/gpu/). |
| Wireshark GUI | Install the [Windows app with Npcap](https://www.wireshark.org/docs/wsug_html_chunked/ChBuildInstallWinInstall.html) for local packet capture; TShark in the toolkit can analyze saved captures. |
| Armitage | Its [creator repository](https://github.com/rsmudge/armitage) is available, but compatibility with this pinned Framework version has not been validated, so it is not part of the launch. |
| BeEF | A [separate server](https://github.com/beefproject/beef/wiki/Installation) requiring its own credentials and configuration. It is not started by this launcher. |
| Greenbone/OpenVAS | An [independent multi-container scanner](https://greenbone.github.io/docs/latest/22.4/container/) with significant storage, memory, and feed-loading requirements. Metasploit has an OpenVAS plugin, but it needs an external scanner service. |
| Sliver | A [separate C2 server](https://github.com/BishopFox/sliver/wiki/Getting-Started) with its own resources and operation configuration. It is not started here. |
| Cobalt Strike | A [licensed product](https://www.cobaltstrike.com/product/quote-request); it cannot be bundled into this fork. |
| Kismet | [Live Wi-Fi capture](https://www.kismetwireless.net/docs/readme/datasources/wifi-linux/) needs a compatible monitor-mode adapter and Linux access to it. Docker Desktop on Windows has [no direct USB passthrough](https://docs.docker.com/desktop/troubleshoot-and-support/faqs/general/), so this launcher does not promise a working Kismet capture service. |

Docker Desktop is already the host runtime for this toolkit. For the cloud
infrastructure part of your list, [Docker Desktop Kubernetes](https://docs.docker.com/desktop/use-desktop/kubernetes/)
is an optional host feature, and [Terraform](https://developer.hashicorp.com/terraform/install)
is a separate host CLI. Neither a Kubernetes cluster nor Terraform provider
configuration is needed to run Metasploit, so the launch button does not
create them or start infrastructure outside this local toolkit.

The [Metasploit plugin guide](https://docs.metasploit.com/docs/using-metasploit/intermediate/how-to-use-plugins.html)
lists sqlmap and OpenVAS plugins. Installing a CLI or starting this toolkit does
not connect those external services automatically.

## Where it runs and what persists

Docker Compose starts PostgreSQL as the `db` service and waits for its health
check before opening the Metasploit console. The console and Toolbox are
temporary containers built from the same image. The `personal-startup.rc`
[resource script](https://docs.rapid7.com/metasploit/resource-scripts/) selects
your `personal` workspace and displays database status. The Toolbox is a shell
in that image, not a separate Metasploit installation. Burp, Wireshark, and
Rust CVE Sniffer run on Windows outside Docker.

| Data | Where it stays |
| --- | --- |
| PostgreSQL workspaces and results | Named Docker volume `db_data` for this Compose project. |
| Framework user settings | Named Docker volume `msf_data`, mounted at `/home/msf/.msf4`. |
| Your Metasploit modules | `personal/modules/`, mounted into Framework's module directory. Follow the layout in [modules/README.md](modules/README.md). |
| Files shared with the Toolbox | `personal/workspace/` on Windows, mounted at `/workspace` in the containers. Put packet captures, memory/disk images, and results here when you need them across sessions. |
| Database password | `personal/.env`, generated on first launch and ignored by Git. Keep this file private and back it up with the database volume. |
| Companion preferences and portable Rust scanner | Ignored `personal/companions.local.json` and `personal/tools/`. |

`Stop-Metasploit.cmd` stops containers but does not remove those volumes or
files. Closing `msfconsole` alone stops its temporary container; PostgreSQL
continues running until you use Stop. Docker Compose project names scope the
volumes, so a test clone can use a distinct `COMPOSE_PROJECT_NAME`. Keep its
`.env` with the matching database volume. The Docker build context excludes
`.env`, `workspace/`, and the portable Windows app.

The Dockerfile pins the Framework image digest, added Alpine package versions,
sqlmap and Nikto source commits, and Volatility 3 package versions. Compose
pins the PostgreSQL image digest. These pins limit version drift; rebuilding
still needs the upstream package and source servers. The optional Windows apps
use their own installers and update schedules.

### Choose which windows open

Copy `companions.example.json` to `companions.local.json` inside `personal/`.
Set `OpenToolbox`, `OpenWireshark`, `OpenBurpSuite`, or
`OpenRustCveSniffer` to `false` to skip an automatic window. Leave a path blank
for discovery, or set `WiresharkPath` and `BurpSuitePath` to installed `.exe`
paths and `RustCveSnifferPath` to `Start Scanner.bat`. Missing companions are
skipped without failing the Metasploit launch. Burp discovery checks Windows
shortcuts, uninstall entries, and common per-user and machine-wide locations.

### Listener reachability

Only port 4444 is published, on Windows `127.0.0.1` by default. For an
authorized lab target on another machine to reach that port, set
`MSF_BIND_ADDRESS` in `.env` to the Windows host's lab-interface IP, then stop
and relaunch. In a reverse handler, `LHOST` is the reachable Windows IP while
`ReverseListenerBindAddress` is `0.0.0.0` inside the container; use `LPORT`
`4444` to match the published port. Windows Firewall must allow the incoming
lab connection. Docker's
[published-port documentation](https://docs.docker.com/engine/network/port-publishing/)
explains the host/container address distinction. Keep the default loopback
binding unless your lab needs another machine to connect.

## Update and recover

Stop the toolkit before updating. From the cloned repository root, run
`git pull --ff-only`, then launch again. The sparse checkout stays sparse and
your ignored `.env`, workspace files, local companion settings, and Docker
volumes are not part of that pull. Back up the `.env` file together with the
Compose project's `db_data` volume before changing pinned versions. If you
maintain a modified fork, change versions and digests in `Dockerfile` and
`compose.yaml` together and keep the previous commit available for rollback.

| Symptom | What to check |
| --- | --- |
| Docker Desktop does not become ready | Open Docker Desktop, select Linux containers with a working WSL 2 backend, wait for the engine, then launch again. |
| Port 4444 is busy | The launcher stops before opening a new console. Close the other program using that host port, or stop an older toolkit instance, then retry. A different Compose project name alone does not change the host port. |
| `.env` is missing but an old database volume exists | Restore the original `.env`; the launcher refuses to invent a new password for that existing database. Stop still works without `.env`. |
| Build or database startup fails | Check the first error in the launch window and verify Docker/network access. With `.env` present, `docker compose -f personal/compose.yaml --project-directory personal logs db` shows database logs. |
| Toolbox says the image is missing | Run `Launch-Metasploit.cmd` once to build it. |
| A desktop app does not open | Run its installer button, then relaunch. For a custom location, set the matching path in `companions.local.json`. Wireshark capture also requires Npcap. |
| The launch button reports an existing console but its window is gone | Use Stop, then Launch to open a fresh console window. |

The buttons were checked on Windows with Docker Desktop on 2026-09-22: a
no-cache image build, a fresh sparse clone in a path containing spaces, a
connected PostgreSQL database, the selected `personal` workspace, and an open
Toolbox. Stop preserved the data volumes. A second launch recovered a workspace
created in the first run. Rust CVE Sniffer's pinned download, checksum checks,
version, and desktop window were also checked. No target scans or exploits were
run. Wireshark and Burp Suite were absent on that test machine, so their actual
GUI launches remain dependent on each reader's Windows installation.
