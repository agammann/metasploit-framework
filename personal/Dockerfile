FROM metasploitframework/metasploit-framework:6.5.5@sha256:a05bb5cac4c4d95b2ebeb972813ce17b2da022d7647c4f17e9537bffa2906ed6

# Keep the command-line lab tools in the same image as Framework. The sqlmap
# revision is fixed so a rebuild does not silently switch to a newer checkout.
ARG SQLMAP_COMMIT=863ff6e0e523073276bf5a725b6c80f2301b06d9
ARG NIKTO_COMMIT=d201dac320fc5187eac75e723dd07a716196ec5a
RUN apk add --no-cache \
      john=1.9.0-r7 hydra=9.5-r1 tshark=4.4.2-r0 \
      aircrack-ng=1.7-r3 sleuthkit=4.12.1-r0 \
      perl=5.40.4-r0 perl-net-ssleay=1.94-r1 perl-json=4.10-r1 \
      perl-io-socket-ssl=2.089-r0 perl-xml-writer=0.900-r2 \
      perl-mime-base64=3.16-r6 perl-xml-libxml=2.0210-r1 \
    && git clone https://github.com/sqlmapproject/sqlmap.git /opt/sqlmap \
    && git -C /opt/sqlmap checkout --detach "$SQLMAP_COMMIT" \
    && rm -rf /opt/sqlmap/.git \
    && ln -s /opt/sqlmap/sqlmap.py /usr/local/bin/sqlmap \
    && git clone https://github.com/sullo/nikto.git /opt/nikto \
    && git -C /opt/nikto checkout --detach "$NIKTO_COMMIT" \
    && rm -rf /opt/nikto/.git \
    && python3 -m venv /opt/volatility3 \
    && /opt/volatility3/bin/pip install --no-cache-dir \
      volatility3==2.28.2 pefile==2024.8.26 \
    && ln -s /opt/volatility3/bin/vol /usr/local/bin/vol

COPY bin/nikto /usr/local/bin/nikto
RUN chmod 755 /usr/local/bin/nikto

# The Metasploit entrypoint creates UID 1000 at startup. Set ownership before
# Docker initializes the named volume mounted at this path.
RUN mkdir -p /home/msf/.msf4 && chown 1000:1000 /home/msf/.msf4
