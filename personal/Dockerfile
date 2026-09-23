FROM metasploitframework/metasploit-framework:6.5.5@sha256:a05bb5cac4c4d95b2ebeb972813ce17b2da022d7647c4f17e9537bffa2906ed6

# Keep the command-line lab tools in the same image as Framework. The sqlmap
# revision is fixed so a rebuild does not silently switch to a newer checkout.
ARG SQLMAP_COMMIT=863ff6e0e523073276bf5a725b6c80f2301b06d9
RUN apk add --no-cache john=1.9.0-r7 hydra=9.5-r1 tshark=4.4.2-r0 \
    && git clone https://github.com/sqlmapproject/sqlmap.git /opt/sqlmap \
    && git -C /opt/sqlmap checkout --detach "$SQLMAP_COMMIT" \
    && rm -rf /opt/sqlmap/.git \
    && ln -s /opt/sqlmap/sqlmap.py /usr/local/bin/sqlmap

# The Metasploit entrypoint creates UID 1000 at startup. Set ownership before
# Docker initializes the named volume mounted at this path.
RUN mkdir -p /home/msf/.msf4 && chown 1000:1000 /home/msf/.msf4
