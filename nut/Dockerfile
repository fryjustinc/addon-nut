ARG BUILD_FROM=ghcr.io/hassio-addons/debian-base:8.1.1
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Setup base
# hadolint ignore=DL3003
RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        nut=2.8.1-5 \
        nut-snmp=2.8.1-5 \
        nut-xml=2.8.1-5 \
        nut-modbus=2.8.1-5 \
        nut-powerman-pdu=2.8.1-5 \
        powerman \
        usbutils=1:018-2 \
        expect \
        telnet \
        snmp \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy root filesystem
COPY rootfs /

# Create symlinks for powerman-pdu driver (installed in /lib/nut by Debian package)
RUN mkdir -p /usr/lib/nut \
    && ln -s /lib/nut/powerman-pdu /usr/lib/nut/powerman-pdu

# Make scripts executable and fix permissions
RUN chmod +x /usr/bin/notify \
    && chmod +x /usr/bin/shutdownhost \
    && chmod +x /usr/bin/test-powerman \
    && chmod +x /usr/bin/test-apc-ap7900b \
    && chmod +x /usr/bin/test-snmp-ups \
    && chmod +x /etc/services.d/*/run \
    && chmod +x /etc/services.d/*/finish \
    && chmod +x /etc/cont-init.d/*.sh \
    && mkdir -p /var/run/nut \
    && chmod 0770 /var/run/nut

# Build arguments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Dale Higgs <dale3h@addons.community>" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Community Add-ons" \
    org.opencontainers.image.authors="Dale Higgs <dale3h@addons.community>" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://addons.community" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
