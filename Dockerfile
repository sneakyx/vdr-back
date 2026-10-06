# =============================================================================
# sneaky/vdr:2.6 - Headless VDR recording server
#
# Replaces:   sneaky/vdr:latest (Ubuntu 18.04, VDR 2.4.0, ~2020, manually extended)
# Base:       Debian 13 "trixie" -> VDR 2.6.9 from Debian packages
# Repo:       sneakyx/vdr-back (Fork of maligin/vdr-back), Branch 2.6
#
# Contract with existing docker-compose.yml (remains 1:1 preserved):
#   devices : /dev/dvb:/dev/dvb   (Digital Devices Octopus [dd01:0003], PCI-Passthrough)
#   volumes : /srv/vdr/video  <- /mnt/bighdd/mediareceiver/vdr  (recordings)
#             /etc/vdr        <- /mnt/container-data/vdr/etc     (plugin configuration)
#             /var/lib/vdr    <- /mnt/container-data/vdr/var    (setup/channels/svdrphosts)
#   ports   : 2004 3000 6419 8001 8002 8008 34890
#
# Plugin set (intentionally minimal, Issue #2):
#   Debian package: epgsearch, streamdev (Server)
#   Source build  : restfulapi (8002, REST API - future tux-media-grabber)
#                   ddci2 (CI adapter for Octopus)
#                   dummydevice (headless)
#                   vnsiserver (Kodi/VNSI)
#                   svdrposd + svdrpservice (existing smartphone app via SVDRP 6419)
#                   live (Web UI 8008)
# Omitted: satip, eepg, xmltv2vdr, robotv, iptv, wirbelscan, femon, vdradmin-am
# =============================================================================

FROM debian:trixie

ARG BUILD_DATE
LABEL org.opencontainers.image.title="sneaky/vdr" \
      org.opencontainers.image.description="VDR 2.6 headless recording server" \
      org.opencontainers.image.version="2.6" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      maintainer="sneaky"

ENV TZ=Europe/Berlin \
    VDRDIR=/usr/include/vdr \
    LIBDIR=/usr/lib/vdr

# -----------------------------------------------------------------------------
# Base system + VDR 2.6.9 + Debian plugins
# (In Debian trixie, streamdev is split into -server/-client; we only need
#  the server. epgsearch is available as vdr-plugin-epgsearch.)
# -----------------------------------------------------------------------------
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates curl git build-essential pkg-config tzdata \
      vdr vdr-dev \
      vdr-plugin-epgsearch \
      vdr-plugin-streamdev-server \
      vdr-plugin-live \
      libssl-dev zlib1g-dev \
      libmagick++-dev \
      libtntnet-dev libcxxtools-dev \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Directories (contract with volume mounts)
# -----------------------------------------------------------------------------
RUN mkdir -p /srv/vdr/video \
             /var/cache/vdr/epgimages \
             /usr/share/vdr/channel-logos \
             /var/lib/vdr/plugins/restfulapi \
             /etc/vdr/command-hooks \
             /etc/drafts

# Baked-in default configurations from repo (conf/):
# - conf/vdr/*     -> /var/lib/vdr/   (setup.conf, channels.conf, svdrphosts.conf)
# - conf/plugins/* -> /etc/vdr/plugins/
# - conf/          -> /etc/drafts/    (fallback source for initial start copy
#                                     mechanism in runvdr.sh)
# In production, these are overridden by volume mounts; they serve only as
# defaults for a fresh start without mounts.
COPY conf/vdr/* /var/lib/vdr/
COPY conf/plugins/* /etc/vdr/plugins/
COPY conf/ /etc/drafts

# -----------------------------------------------------------------------------
# Source builds: Plugins without (matching) Debian package
# Standard VDR plugin build: make && make install (VDRDIR/LIBDIR from ENV above).
# If make reports a missing header: add the corresponding -dev package above
# in apt-get and rebuild (dependencies see respective repo).
# -----------------------------------------------------------------------------

# restfulapi - REST API on port 8002, actively maintained (yaVDR, as of 10/2026)
# Fix: The plugin Makefile overwrites CXXFLAGS itself (without -fPIC, which
# vdr.pc in trixie does not provide) -> Linking as shared library fails.
# The sed appends -fPIC to the "export CXXFLAGS =" line of the Makefile.
RUN git clone --depth 1 https://github.com/yavdr/vdr-plugin-restfulapi.git /src/restfulapi && \
    cd /src/restfulapi && \
    sed -i '/^export CXXFLAGS =/ s/$/ -fPIC/' Makefile && \
    make && make install && \
    cp -r web /var/lib/vdr/plugins/restfulapi/webapp && \
    rm -rf /src/restfulapi

# ddci2 - CI adapter from Digital Devices (Octopus + CI module)
RUN git clone --depth 1 https://github.com/jasmin-j/vdr-plugin-ddci2.git /src/ddci2 && \
    cd /src/ddci2 && \
    sed -i '/^CXXFLAGS/ s/$/ -fPIC/; /^export CXXFLAGS/ s/$/ -fPIC/' Makefile && \
    make && make install && rm -rf /src/ddci2

# dummydevice - headless: Dummy as primary device,
# the Octopus remains completely free for recordings
RUN git clone --depth 1 https://github.com/flensrocker/vdr-plugin-dummydevice.git /src/dummydevice && \
    cd /src/dummydevice && \
    sed -i '/^CXXFLAGS/ s/$/ -fPIC/; /^export CXXFLAGS/ s/$/ -fPIC/' Makefile && \
    make && make install && rm -rf /src/dummydevice

# vnsiserver - Streaming for Kodi clients (VNSI, port 34890)
RUN git clone --depth 1 https://github.com/vdr-projects/vdr-plugin-vnsiserver.git /src/vnsi && \
    cd /src/vnsi && \
    sed -i '/^CXXFLAGS/ s/$/ -fPIC/; /^export CXXFLAGS/ s/$/ -fPIC/' Makefile && \
    make && make install && rm -rf /src/vnsi

# svdrposd + svdrpservice - SVDRP OSD/service (basis of the existing smartphone app!)
RUN git clone --depth 1 https://github.com/vdr-projects/vdr-plugin-svdrposd.git /src/svdrposd && \
    cd /src/svdrposd && \
    sed -i '/^CXXFLAGS/ s/$/ -fPIC/; /^export CXXFLAGS/ s/$/ -fPIC/' Makefile && \
    make && make install && rm -rf /src/svdrposd
RUN git clone --depth 1 https://github.com/vdr-projects/vdr-plugin-svdrpservice.git /src/svdrpservice && \
    cd /src/svdrpservice && \
    sed -i '/^CXXFLAGS/ s/$/ -fPIC/; /^export CXXFLAGS/ s/$/ -fPIC/' Makefile && \
    make && make install && rm -rf /src/svdrpservice

# live - Web UI on 8008: NOT as source build! The rofafor Git code is
# incompatible with cxxtools 3.x (trixie) (LOG_ERROR/syslog macro conflict).
# Debian trixie provides a maintained vdr-plugin-live 3.5.0-1 via apt
# (above in the package list) - which is more current than the Git state and builds.

# -----------------------------------------------------------------------------
# Startup script: exists as separate file in repo (runvdr.sh) - maintained there,
# not generated via printf in Dockerfile (pattern from the old vdr-back repo).
# -----------------------------------------------------------------------------
COPY runvdr.sh /
RUN chmod +x /runvdr.sh

# -----------------------------------------------------------------------------
# Runtime
# USER vdr: Debian creates the vdr user during package installation (video group).
# If DVB devices in the container have no permissions: in compose set
# "group_add: [video]" or temporarily remove the block.
# -----------------------------------------------------------------------------
USER vdr

EXPOSE 2004 3000 6419 8001 8002 8008 34890

# restfulapi as health indicator: If port 8002 responds, VDR is running
HEALTHCHECK --interval=60s --timeout=5s --start-period=90s --retries=3 \
  CMD curl -fsS http://localhost:8002/ > /dev/null || exit 1

ENTRYPOINT ["/runvdr.sh"]