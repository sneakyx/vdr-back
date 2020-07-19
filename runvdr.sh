#!/bin/sh

mkdir -p /etc/vdr/command-hooks

if [ ! -f /var/lib/vdr/svdrphosts.conf ]; then
  cp /etc/drafts/svdrphosts.conf /var/lib/vdr/svdrphosts.conf
fi
/usr/bin/vdr --chartab=ISO-8859-1 --port=6419 -P svdrposd -P svdrpservice -P dummydevice -P epgsearch -P streamdev-server -P vnsiserver -P 'live -i 0.0.0.0 -p 8008' -P 'epgsearch --config=/etc/vdr/plugins/epgsearch' -P ddci2

