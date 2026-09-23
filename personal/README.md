# Personal Metasploit setup for Windows

This folder runs Metasploit Framework 6.5.5 in Docker Desktop with a local
PostgreSQL database. The container includes Nmap. Both container images are
pinned to a specific digest, so ordinary restarts use the same build.

## First launch

1. Install Docker Desktop and select Linux containers.
2. In PowerShell, run `./Start-Metasploit.ps1` from this folder. The script
   starts Docker Desktop if needed, creates a local database password, builds
   the image, starts PostgreSQL, and opens `msfconsole`.
3. Type `version` and `db_status` in `msfconsole` to check the installation.
4. Type `exit` to leave the console. Run `./Stop-Metasploit.ps1` to stop the
   database when you are finished.

For a first lab session, create a Metasploit workspace with `workspace -a lab`.
The container's Nmap integration can record results in that workspace; for
example, `db_nmap -sT -sV 192.0.2.10` shows the command shape. Replace the
sample address with an authorized lab target. Use `hosts` and `services` to
review results.

The first launch downloads container images and can take several minutes.
Subsequent launches reuse the images and database. The password is stored in
the untracked `.env` file. Keep that file private and retain it if you want to
reuse the database volume.

## Use your fork without downloading the full source tree

Run these commands in PowerShell from a folder where you want the setup:

```powershell
git clone --depth 1 --filter=blob:none --sparse https://github.com/agammann/metasploit-framework.git
Set-Location metasploit-framework
git sparse-checkout set personal
./personal/Start-Metasploit.ps1
```

Your own Metasploit modules go in `personal/modules/` using the normal module
directory layout. Files in `personal/workspace/` are shared with the container
at `/workspace` and stay on your computer. The database and Metasploit user
data live in Docker volumes.

The [feature list you shared](https://www.webasha.com/blog/top-10-features-of-metasploit-for-ethical-hackers)
maps mainly to Framework capabilities already present in the pinned image:
modules, payloads, Meterpreter, and post modules. This setup adds a persistent
database for scan results, Nmap integration, and a place for your own modules.
The Social Engineering Toolkit is a separate project, and Metasploit Pro is a
separate paid product; either can be evaluated later if your work calls for it.

Port 4444 is bound to `127.0.0.1` by default. If a lab target on another
machine needs to connect to a listener, set `MSF_BIND_ADDRESS` to your Windows
host's lab interface address in `.env`, restart the setup, and configure the
Metasploit listener for that address. Keep this scoped to systems you are
authorized to test.

To upgrade later, change the pinned Metasploit and PostgreSQL versions and
digests in `Dockerfile` and `compose.yaml`, then run the start script again.
Keep the previous commit so you can roll back if an update breaks your setup.
