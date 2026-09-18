# Build the dedicated server from verified workflow downloads.
FROM debian:trixie-slim
ARG VALHEIM_VERSION
ARG VALHEIM_BUILD_ID
ARG BEPINEX_VERSION
ARG IMAGE_FINGERPRINT
ARG IMAGE_REVISION
LABEL org.opencontainers.image.title="Valheim dedicated server with BepInEx" \
    org.opencontainers.image.description="Valheim Dedicated Server ${VALHEIM_VERSION} (Steam Build ID ${VALHEIM_BUILD_ID}) with BepInExPack_Valheim ${BEPINEX_VERSION}, based on debian:trixie-slim." \
    org.opencontainers.image.version="${VALHEIM_VERSION}" \
    org.opencontainers.image.source="https://github.com/landoria-gaming/valheim-server-image" \
    org.opencontainers.image.revision="${IMAGE_REVISION}" \
    io.landoria.image.fingerprint="${IMAGE_FINGERPRINT}" \
    io.landoria.valheim.version="${VALHEIM_VERSION}" \
    io.landoria.valheim.build-id="${VALHEIM_BUILD_ID}" \
    io.landoria.bepinex.version="${BEPINEX_VERSION}"
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates libatomic1 libstdc++6 libpulse0 libpulse-mainloop-glib0 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --uid 1000 --create-home valheim \
    && install -d -o valheim -g valheim /opt/valheim /opt/bepinex-default /savedir /BepInEx \
        /home/valheim/.config/unity3d/IronGate \
    && ln -s /savedir /home/valheim/.config/unity3d/IronGate/Valheim
COPY --chown=valheim:valheim valheim/ /opt/valheim/
COPY --chown=valheim:valheim bepinex/ /opt/valheim/
COPY --chmod=0755 valheim-entrypoint.sh /usr/local/bin/valheim-entrypoint
RUN test -s /opt/valheim/BepInEx/core/BepInEx.Preloader.dll \
    && chmod +x /opt/valheim/valheim_server.x86_64 \
    && cp -a /opt/valheim/BepInEx/. /opt/bepinex-default/ \
    && rm -rf /opt/valheim/BepInEx \
    && ln -s /BepInEx /opt/valheim/BepInEx \
    && chown -R valheim:valheim /opt/bepinex-default
USER valheim
WORKDIR /opt/valheim
VOLUME ["/savedir", "/BepInEx"]
EXPOSE 2456/udp 2457/udp
STOPSIGNAL SIGINT
ENTRYPOINT ["/usr/local/bin/valheim-entrypoint"]
