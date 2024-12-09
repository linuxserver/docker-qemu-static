# syntax=docker/dockerfile:1

FROM debian:bookworm AS buildstage

ARG QEMU_VERSION

RUN \
  echo "**** install build deps ****" && \
  apt-get update && \
  apt-get install -y \
    curl \
    xz-utils

RUN \
  echo "**** ingest external assets ****" && \
  mkdir -p \
    /build-out/qemu \
    /build-out/usr/bin \
    /tmp/qemu && \
  if [ -z "${QEMU_VERSION}" ]; then \
    QEMU_VERSION=$(curl -sX GET https://deb.debian.org/debian/dists/bookworm-backports/main/binary-amd64/Packages.xz | xz -dc |grep -A 7 -m 2 'Package: qemu-user$' | awk -F ': ' '/Version/{print $2;exit}' | awk -F ':' '{print $2}'); \
  fi && \
  curl -o \
    /tmp/qemu.deb -L \
    "http://deb.debian.org/debian/pool/main/q/qemu/qemu-user_${QEMU_VERSION}_amd64.deb" && \
  cd /tmp && \
  dpkg-deb -R \
    qemu.deb \
    /tmp/qemu && \
  cp \
    /tmp/qemu/usr/bin/* \
    /build-out/qemu && \
  curl -o \
    /build-out/usr/bin/qemu-binfmt-conf -L \
    "https://raw.githubusercontent.com/qemu/qemu/refs/heads/master/scripts/qemu-binfmt-conf.sh" && \
  chmod +x /build-out/usr/bin/qemu-binfmt-conf

# runtime stage
FROM alpine:latest

# set version label
ARG BUILD_DATE
ARG VERSION
ARG QEMU_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

# Add build assets
COPY --from=buildstage /build-out/ /

# add local files
COPY /root /

ENTRYPOINT ["/register"]
