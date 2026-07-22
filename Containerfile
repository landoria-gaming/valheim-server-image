FROM debian:trixie-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG BEPINEX_VERSION=5.4.2333
ARG BEPINEX_SHA256=5dd24ccbcaa9260f714b200f23c4c15547e2aa5f06906cafcc0dee56db1bf716

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl unzip libatomic1 libpulse0 \
        libstdc++6:i386 libgcc-s1:i386 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 1000 --shell /usr/sbin/nologin valheim \
    && install -d -o valheim -g valheim \
        /opt/steamcmd /opt/valheim-server /opt/bepinex-default-config \
        /data /mods/plugins /mods/config

USER valheim
WORKDIR /opt/steamcmd

RUN curl --fail --location --show-error --silent \
        https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
        --output /tmp/steamcmd.tar.gz \
    && tar -xzf /tmp/steamcmd.tar.gz -C /opt/steamcmd \
    && rm /tmp/steamcmd.tar.gz \
    && /opt/steamcmd/steamcmd.sh \
        +force_install_dir /opt/valheim-server \
        +login anonymous \
        +app_update 896660 validate \
        +quit

RUN curl --fail --location --show-error --silent \
        "https://thunderstore.io/package/download/denikson/BepInExPack_Valheim/${BEPINEX_VERSION}/" \
        --output /tmp/bepinex.zip \
    && echo "${BEPINEX_SHA256}  /tmp/bepinex.zip" | sha256sum --check --strict \
    && unzip -q /tmp/bepinex.zip -d /tmp/bepinex \
    && cp -a /tmp/bepinex/BepInExPack_Valheim/. /opt/valheim-server/ \
    && cp /opt/valheim-server/BepInEx/config/BepInEx.cfg \
        /opt/bepinex-default-config/BepInEx.cfg \
    && rm -rf /tmp/bepinex /tmp/bepinex.zip \
    && chmod +x /opt/valheim-server/start_server_bepinex.sh

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends libpulse-mainloop-glib0 \
    && rm -rf /var/lib/apt/lists/*
USER valheim

COPY --chown=valheim:valheim --chmod=0755 valheim-entrypoint.sh /usr/local/bin/valheim-entrypoint

WORKDIR /opt/valheim-server
VOLUME ["/data", "/mods/plugins", "/mods/config"]
STOPSIGNAL SIGINT
ENTRYPOINT ["/usr/local/bin/valheim-entrypoint"]
