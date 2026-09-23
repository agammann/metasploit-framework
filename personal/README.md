# Personal Metasploit toolkit for Windows

This setup runs Metasploit Framework 6.5.5 and PostgreSQL in Docker Desktop.
It includes Meterpreter payloads, Nmap, sqlmap, John the Ripper, THC-Hydra,
and TShark (Wireshark's command-line analyzer). The Framework and database
images, sqlmap revision, and added Alpine packages are pinned. Your database,
Framework settings, modules, and shared files persist across launches.

## Launch with one double-click

1. Install [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/) and use Linux containers.
2. Double-click **`Launch-Metasploit.cmd`** in this folder. It starts Docker
   Desktop if needed, builds the toolkit image, starts PostgreSQL, and opens
   `msfconsole` in the same window. The first launch can take several minutes.
3. At the Metasploit prompt, run `version` and `db_status` to check the setup.
4. Double-click **`Toolbox.cmd`** when you want a shell with the bundled
   command-line tools. Files in `workspace/` appear there at `/workspace`.
5. Type `exit` to close either console. Double-click **`Stop-Metasploit.cmd`**
   to stop the database; your Docker volumes remain intact.

The database runs while you use the console. Closing `msfconsole` stops its
temporary container; the database stays up until you use the Stop button.
Launching again reuses the images and saved data. Start one Metasploit console
at a time because the configured local port is shared.

The launcher generates a random database password in the untracked `.env`
file. Keep it private and retain it if you want to reuse your database volume.
The Docker build context excludes `.env` and your workspace files.

## What's included

| Tool | How to use it here |
| --- | --- |
| Metasploit Framework and Meterpreter | Open `Launch-Metasploit.cmd`. Meterpreter payloads are part of the pinned Framework image. |
| Nmap | Available inside the console via `db_nmap` and inside `Toolbox.cmd` as `nmap`. |
| sqlmap | Available as `sqlmap` inside `Toolbox.cmd`. This installs the CLI; Metasploit's sqlmap plugin needs a separately configured sqlmap API service. |
| John the Ripper | Available as `john` inside `Toolbox.cmd`. Save input and results under `/workspace` if they need to persist. |
| THC-Hydra | Available as `hydra` inside `Toolbox.cmd`. It runs only when you invoke it. |
| TShark | Available as `tshark` inside `Toolbox.cmd` for packet-capture files in `/workspace`. Install the Windows Wireshark app separately for host capture and its Npcap driver. |

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

These have different installation or runtime needs, so the launch button does
not claim to start them:

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
