# Description
VDR headless server based on the Ubuntu 18.04 image and yaVDR Ubuntu repository

# Contents
- vdr (2.4.0/2.4.0) - The Video Disk Recorder
- conflictcheckonly (0.0.1) - Direct access to epgsearch's conflict check menu
- ddci2 (1.0.5) - External Digital Devices CI-Adapter
- dummydevice (2.0.0) - Output device that does nothing
- eepg (0.0.6pre) - Parses Extended EPG data
- epgfixer (0.3.1) - Fix bugs in EPG
- epgsearch (2.4.0) - search the EPG for repeats and more
- epgsearchonly (0.0.1) - Direct access to epgsearch's search menu
- femon (2.4.1) - DVB Signal Information Monitor (OSD)
- iptv (2.4.0) - Experience the IPTV
- live (2.3.1) - Live Interactive VDR Environment
- quickepgsearch (0.0.1) - Quick search for broadcasts
- restfulapi (0.2.6.5) - Offers a RESTful-API to retrieve data from VDR
- robotv (0.13.3) - roboTV Server
- satip (2.4.1) - SAT>IP Devices
- streamdev-server (0.6.1-git) - VDR Streaming Server
- svdrposd (1.0.0) - Publish OSD menu via SVDRP
- svdrpservice (1.0.0) - SVDRP client
- vnsiserver (1.8.0) - VDR-Network-Streaming-Interface (VNSI) Server
- wirbelscan (2017.06.04) - DVB channel scan for VDR
- xmltv2vdr (0.2.1) - Imports xmltv epg into vdr

# VDR repo
- ppa:aap/vdr
- ppa:yavdr/experimental-vdr

# channels.conf
http://channelpedia.yavdr.com/gen/DVB-S/S19.2E/S19.2E_complete_sorted_by_groups.channels.conf

# Run Docker image
 ```docker run --name vdr-server -it -d  --restart unless-stopped --device=/dev/dvb:/dev/dvb -v /srv/vdr/video:/srv/vdr/video -v vdr_etc:/etc/vdr -v vdr_varlib:/var/lib/vdr -p 2004:2004 -p 3000:3000 -p 6419:6419 -p 8002:8002 -p 8008:8008 -p 8001:8001 -p 34890:34890 sneaky/vdr:latest```

### where:
- ```/srv/vdr/videos``` is the recordings directory
- ```/dev/dvb``` is the DVB-S2 card
- ```vdr_etc``` and ```vdr_varlib``` are the volumes to store the persistent changes in "channels.conf" or "setup.conf"


