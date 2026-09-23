# Personal Metasploit toolkit for Windows

This setup runs Metasploit Framework 6.5.5 and PostgreSQL in Docker Desktop.
It includes Meterpreter payloads and a command-line toolbox for network, web,
wireless capture-file, and forensic work. The Framework and database images,
source revisions, Python packages, and added Alpine packages are pinned. Your
database, Framework settings, modules, and shared files persist across launches.

## Launch with one double-click

1. Install [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/) and use Linux containers.
2. Double-click **`Launch-Metasploit.cmd`** in this folder. It starts Docker
   Desktop if needed, builds the toolkit image, starts PostgreSQL, opens a
   separate Toolbox window, and opens `msfconsole` in the launch window. The
   first launch can take several minutes.
3. The console selects your `personal` workspace on startup. Run `version` and
   `db_status` to check the setup. Installed Wireshark and Burp Suite desktop
   apps also open automatically when found at their standard Windows paths.
4. Files in `workspace/` appear in the Toolbox at `/workspace`. Type `exit` to
   close either console. Double-click **`Stop-Metasploit.cmd`** to stop the
   Docker services; your data volumes remain intact.

The database runs while you use the console. Closing `msfconsole` stops its
temporary container; the database stays up until you use the Stop button.
Launching again reuses the images and saved data. Start one Metasploit console
at a time because the configured local port is shared.

The launcher generates a random database password in the untracked `.env`
file. Keep it private and retain it if you want to reuse your database volume.
The Docker build context excludes `.env` and your workspace files.

To change companion startup, copy `companions.example.json` to the ignored
`companions.local.json`. Set `OpenToolbox`, `OpenWireshark`, or `OpenBurpSuite`
to `false` to skip a window. If auto-detection misses an installed desktop
app, put its full `.exe` path in `WiresharkPath` or `BurpSuitePath`. Missing
apps are skipped without blocking Metasploit. The Toolbox can also be opened
later with `Toolbox.cmd`. The Metasploit startup commands are in
`personal-startup.rc`; they run after the database connection resource script.
They create/select the `personal` workspace and display database status using
Metasploit's [resource script feature](https://docs.rapid7.com/metasploit/resource-scripts/).

If you want the two Windows desktop apps, double-click
`Install-Desktop-Companions.cmd` once. It uses Windows Package Manager to
install Wireshark and Burp Suite Community Edition and leaves installer and
license prompts for you to review. Restart the Metasploit launcher afterward.
Wireshark host capture also requires a working Npcap installation.

## What's included

| Tool | How to use it here |
| --- | --- |
| Metasploit Framework and Meterpreter | Open `Launch-Metasploit.cmd`. Meterpreter payloads are part of the pinned Framework image, and the `personal` workspace loads automatically. |
| Nmap | Available inside the console via `db_nmap` and inside `Toolbox.cmd` as `nmap`. |
| sqlmap | Available as `sqlmap` inside `Toolbox.cmd`. This installs the CLI; Metasploit's sqlmap plugin needs a separately configured sqlmap API service. |
| John the Ripper | Available as `john` inside `Toolbox.cmd`. Save input and results under `/workspace` if they need to persist. |
| THC-Hydra | Available as `hydra` inside `Toolbox.cmd`. It runs only when you invoke it. |
| TShark | Available as `tshark` inside `Toolbox.cmd` for packet-capture files in `/workspace`. Install the Windows Wireshark app separately for host capture and its Npcap driver. |
| Nikto | Available as `nikto` inside `Toolbox.cmd` for authorized web-app checks. |
| Aircrack-ng | Available as `aircrack-ng` inside `Toolbox.cmd` for existing wireless capture files in `/workspace`. Live monitor-mode capture is not provided by Docker Desktop. |
| Volatility 3 | Available as `vol` inside `Toolbox.cmd` for memory images in `/workspace`. |
| Sleuth Kit | Forensic commands such as `fls` and `mmls` are available inside `Toolbox.cmd` for disk images in `/workspace`. |

To verify that Meterpreter is present without starting a session, run this in
PowerShell after the first launch:

```powershell
docker run --rm personal-metasploit:6.5.5 ./msfvenom -l payloads |
  Select-String -Pattern 'meterpreter'
```

The pinned image includes `windows/x64/meterpreter/reverse_tcp` and
`linux/x64/meterpreter/reverse_tcp`, among other variants. The
[Metasploit payload guide](https://docs.metasploit.com/docs/using-metasploit/basics/how-payloads-work.html)
explains the payload types. For a first lab session, `workspace -a lab` creates
a Metasploit workspace. `db_nmap` can record authorized lab scan results there;
`hosts` and `services` display the imported data.

## Other tools from your list

These have different installation or runtime needs. The launch button opens
Burp Suite and Wireshark when they are installed, but does not install them or
start the separate services below:

| Tool | Practical setup |
| --- | --- |
| Burp Suite | Install the [Windows desktop app](https://portswigger.net/burp/documentation/desktop/getting-started/download-and-install). You can place exported requests or logs in `workspace/` for use with sqlmap. Professional features require your own license. |
| Hashcat | Install [Hashcat for Windows](https://hashcat.net/hashcat/) for GPU use. Docker Desktop GPU support on Windows has specific [hardware and WSL2 requirements](https://docs.docker.com/desktop/features/gpu/). |
| Wireshark GUI | Install the [Windows app with Npcap](https://www.wireshark.org/docs/wsug_html_chunked/ChBuildInstallWinInstall.html) for local packet capture; TShark in the toolkit can analyze saved captures. |
| Armitage | Its [creator repository](https://github.com/rsmudge/armitage) is a historical release. Compatibility with this Framework version has not been validated, so it is not part of the stable launch. |
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

## Get the setup from your fork

Run these commands in PowerShell from a folder where you want the setup:

```powershell
git clone --depth 1 --filter=blob:none --sparse https://github.com/agammann/metasploit-framework.git
Set-Location metasploit-framework
git sparse-checkout set personal
```

Open `personal/` in File Explorer and double-click `Launch-Metasploit.cmd`.
Your own Metasploit modules go in `personal/modules/` using the normal module
directory layout. Files in `personal/workspace/` are shared with the container
at `/workspace` and stay on your computer. Database and Framework user data
live in Docker volumes.

Port 4444 is bound to `127.0.0.1` by default. For a lab target on another
machine to reach a listener, set `MSF_BIND_ADDRESS` to your Windows host's lab
interface address in `.env`, restart the setup, and configure the listener for
that address. Only use this against systems you are authorized to test.

To upgrade later, update the pinned versions and digests in `Dockerfile` and
`compose.yaml`, then launch again. Keep the previous Git commit so you can roll
back if an update breaks your setup.
