FROM metasploitframework/metasploit-framework:6.5.5@sha256:a05bb5cac4c4d95b2ebeb972813ce17b2da022d7647c4f17e9537bffa2906ed6

# The Metasploit entrypoint creates UID 1000 at startup. Set ownership before
# Docker initializes the named volume mounted at this path.
RUN mkdir -p /home/msf/.msf4 && chown 1000:1000 /home/msf/.msf4
