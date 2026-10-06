#!/bin/sh

mkdir -p /etc/vdr/command-hooks

if [ ! -f /var/lib/vdr/svdrphosts.conf ]; then
  cp /etc/drafts/vdr/svdrphosts.conf /var/lib/vdr/svdrphosts.conf
fi

# Plugin list intentionally hardcoded; conf.d/ is not used for plugin selection.
# --video/--config explicitly set to match the volume mounts.
# --chartab=ISO-8859-1: channels.conf is encoded this way.
exec /usr/bin/vdr \
  --video=/srv/vdr/video \
  --config=/var/lib/vdr \
  --chartab=ISO-8859-1 \
  --port=6419 \
  -P svdrposd -P svdrpservice -P dummydevice \
  -P "epgsearch --config=/etc/vdr/plugins/epgsearch" \
  -P streamdev-server -P vnsiserver \
  -P "live -i 0.0.0.0 -p 8008" \
  -P "restfulapi --port=8002 --ip=0.0.0.0 --epgimages=/var/cache/vdr/epgimages --channellogos=/usr/share/vdr/channel-logos --webapp=/var/lib/vdr/plugins/restfulapi/webapp" \
  -P ddci2