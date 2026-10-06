# vdr-back

Docker image for a **headless VDR recording server** – based on Debian 13
("trixie") with **VDR 2.6.9** from the official Debian packages.

This branch (`2.6`) replaces the legacy build (Ubuntu 18.04 / VDR 2.4.0 from
the yaVDR PPAs, circa 2020). It is a complete rewrite: the image now builds
from current Debian packages and maintained plugin sources, includes a
proper start script, and ships a REST API (restfulapi) that actually starts.

## What's inside
| Component          | Source                                                                                           | Notes                                                                                                                                |
|--------------------|--------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------|
| VDR 2.6.9          | Debian package (`vdr`)                                                                           |                                                                                                                                      |
| epgsearch          | Debian package                                                                                   | Search timers, EPG search                                                                                                            |
| streamdev (server) | Debian package (`vdr-plugin-streamdev-server`)                                                   | Streaming via VTP/HTTP, port 3000                                                                                                    |
| live               | Debian package (`vdr-plugin-live` 3.5.0)                                                         | Web UI on port 8008. Not built from Git: upstream code is incompatible with cxxtools 3.x; the Debian package is maintained and newer |
| restfulapi         | Source build ([yavdr fork](https://github.com/yavdr/vdr-plugin-restfulapi), actively maintained) | REST API on port 8002, serves the bundled web app                                                                                    |
| ddci2              | Source build ([jasmin-j](https://github.com/jasmin-j/vdr-plugin-ddci2))                          | Digital Devices standalone CI support                                                                                                |
| dummydevice        | Source build ([flensrocker fork](https://github.com/flensrocker/vdr-plugin-dummydevice))         | Headless operation: no output device, the tuner stays free for recordings                                                            |
| vnsiserver         | Source build ([vdr-projects](https://github.com/vdr-projects/vdr-plugin-vnsiserver))             | Kodi/VNSI clients, port 34890                                                                                                        |
| svdrposd           | Source build ([vdr-projects](https://github.com/vdr-projects/vdr-plugin-svdrposd))               | Publish OSD menus via SVDRP, port 6419                                                                                               |
| svdrpservice       | Source build ([vdr-projects](https://github.com/vdr-projects/vdr-plugin-svdrpservice))           | SVDRP client service                                                                                                                 |

Omitted on purpose (compared to the legacy image): satip, eepg, epgfixer,
xmltv2vdr, robotv, iptv, wirbelscan, femon, dvbapi, svdrpext, vdradmin-am.
They can be added back if ever needed – see the plugin Makefiles of the
[VDR project](https://github.com/vdr-projects).

### Build quirks worth knowing

- **Debian trixie splits streamdev** into `vdr-plugin-streamdev-server` and
  `-client`; only the server is needed.
- Several plugin Makefiles set their own `CXXFLAGS` without `-fPIC` (which
  `vdr.pc` does not provide in trixie), so linking the shared library fails.
  The Dockerfile appends `-fPIC` to the relevant Makefile lines via `sed`.
- The `live` plugin is **not** built from the upstream Git repository: the
  code there is incompatible with cxxtools 3.x (LOG_ERROR/syslog macro
  conflict). The maintained Debian package (3.5.0) is used instead.
- The plugin list in `runvdr.sh` is **intentionally hardcoded**. VDR's
  `conf.d/` mechanism is not used for plugin selection.
- On first start, if `/var/lib/vdr/svdrphosts.conf` does not exist, a
  default is copied from the image (`/etc/drafts/vdr/svdrphosts.conf`).

## Ports
| Port  | Purpose                             |
 |-------|-------------------------------------|
| 6419  | SVDRP (remote control, OSD service) |
| 8002  | restfulapi (REST API + web app)     |
| 8008  | live (web UI)                       |
| 3000  | streamdev server (VTP streaming)    |
| 2004  | streamdev HTTP streaming            |
| 8001  | streamdev (additional)              |
| 34890 | vnsiserver (Kodi)                   |

## Build

```bash
git clone https://github.com/sneakyx/vdr-back.git
cd vdr-back
git checkout 2.6
docker build -t sneaky/vdr:2.6 --build-arg BUILD_DATE=$(date -I) .
```

## Run

The container expects a DVB device to be passed through. Adjust the volume
paths to your setup:

```bash
docker run --name vdr-server -it -d --restart unless-stopped \
  --device=/dev/dvb:/dev/dvb \
  -v /srv/vdr/video:/srv/vdr/video \
  -v vdr_etc:/etc/vdr \
  -v vdr_varlib:/var/lib/vdr \
  -p 2004:2004 -p 3000:3000 -p 6419:6419 \
  -p 8001:8001 -p 8002:8002 -p 8008:8008 -p 34890:34890 \
  sneaky/vdr:2.6
```

### Volumes
| Container path   | Content                                                     |
 |------------------|-------------------------------------------------------------|
| `/srv/vdr/video` | Recordings                                                  |
| `/etc/vdr`       | Plugin configuration (`conf.d/`, `plugins/`)                |
| `/var/lib/vdr`   | VDR data (`setup.conf`, `channels.conf`, `svdrphosts.conf`) |

The image ships baked-in defaults under `conf/` (channels.conf, setup.conf,
svdrphosts.conf, streamdev/vnsiserver plugin configs). In normal operation
these are overridden by the volume mounts; they only serve as defaults for
a fresh start without mounts.

### Configuration notes

- `channels.conf` is expected in ISO-8859-1 encoding (`--chartab=ISO-8859-1`
  in `runvdr.sh`). A current channel list for Astra 19.2°E can be generated
  at <http://channelpedia.yavdr.com/gen/DVB-S/S19.2E/> (kept from the legacy
  README; convert encoding if needed).
- SVDRP access is restricted via `svdrphosts.conf` – adjust it to your
  network.

### Health check

The image ships a `HEALTHCHECK` that probes the restfulapi on port 8002.
If that port answers, the VDR is up.

## Legacy

The `master` branch contains the original build (forked from
[maligin/vdr-back](https://github.com/maligin/vdr-back)): Ubuntu 18.04,
VDR 2.4.0 from the yaVDR PPAs, with `start-vdr.sh` / `start-vdr-vol.sh`
helper scripts from the upstream project. It is kept for reference only.

## License

VDR and its plugins are GPL-licensed; this repository only contains build
and configuration files. See `LICENSE` and the individual plugin
repositories for their licenses.