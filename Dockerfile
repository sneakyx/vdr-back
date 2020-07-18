# baseimage - start with Ubuntu 18.04
FROM ubuntu:18.04
MAINTAINER sneaky <info@rothaarsystems.de>

# set language
ENV LANG de_DE.UTF-8
ENV LC_ALL de_DE.UTF-8
ENV VDR_LANG de_DE.UTF-8
ENV TZ Europe/Berlin

# generate locates
RUN apt clean && apt update && apt install -y locales gnupg
RUN locale-gen de_DE.UTF-8 en_US.UTF-8

# import gpg key && copy repo
COPY conf/yavdr-bionic.list /etc/apt/sources.list.d/
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys FFEBD240
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8103B360

# update the image to the latest state 
RUN apt update && apt upgrade -y

# install vdr, vdr-plugins 
RUN  apt-get install -y \
  wget \
  vdr \
  vdr-plugin-ddci2 \
  vdr-plugin-dummydevice \
  vdr-plugin-dvbapi \
  vdr-plugin-eepg \
  vdr-plugin-epgfixer \
  vdr-plugin-epgsearch \
  vdr-plugin-iptv \
  vdr-plugin-live \
  vdr-plugin-restfulapi \
  vdr-plugin-robotv \
  vdr-plugin-satip \
  vdr-plugin-streamdev-server \
  vdr-plugin-vnsiserver \
  vdr-plugin-wirbelscan \
  vdr-plugin-xmltv2vdr \
  vdr-plugin-femon \
  vdr-plugin-svdrpservice \
  vdr-plugin-svdrposd \
  vdr-plugin-svdrpext \
  vdradmin-am


#wirbelscancontrol
RUN cd /tmp &&\
 wget https://www.gen2vdr.de/wirbel/wirbelscancontrol/vdr-wirbelscancontrol-0.0.2.tgz && \
 tar -xf vdr-wirbelscancontrol-0.0.2.tgz -C /etc/vdr/plugins/ && \
 mv /etc/vdr/plugins/wirbelscancontrol-0.0.2 /etc/vdr/plugins/wirbelscancontrol

# copy vdr configs
COPY conf/vdr/* /var/lib/vdr/

# copy vdr plugin configs
COPY conf/plugins/* /etc/vdr/plugins/

# clean apt leftovers
RUN  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# set permissions
RUN \
  chown -R vdr:vdr /etc/vdr /var/lib/vdr /srv/vdr
 
ENV HOME /var/lib/vdr
WORKDIR /var/lib/vdr

# volume mappings
VOLUME /srv/vdr /etc/vdr /var/lib/vdr

# copy startcmd
COPY runvdr.sh /

RUN mkdir /var/run/vdradmin-am
RUN echo 'ENABLED="1"' > /etc/default/vdradmin-am
RUN echo 'NICE="10"' >>  /etc/default/vdradmin-am

RUN echo 'ENABLED=1' > /etc/default/vdr

# expose necessary ports
EXPOSE 2004 3000 6419 8002 8008 34890 8001

USER vdr

CMD [ "/runvdr.sh" ]
