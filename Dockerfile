#
# Dockerfile for alpine-linux-rc-upgrade-server mikrotik-docker-image
# (C) 2023-2024 DL7DET
#

ARG ALPINE_VERSION='alpine:latest'
FROM --platform=$TARGETPLATFORM $('alpine:latest':$ALPINE_VERSION) AS base

# Preset Metadata parameters and build-arg parameters
ARG BUILD
ARG PROD_VERSION
ARG DEVEL_VERSION
ARG ALPINE_VERSION
ARG LINUX_VERSION
ARG COMMIT_SHA
ENV USER=mikrotik
ENV WEBUSER=apache
ENV HOME=/home/$USER

# Set Metadata for docker-image
LABEL org.opencontainers.image.authors="DL7DET <detlef@lampart.de>" 
LABEL org.opencontainers.image.licenses="MIT License"
LABEL org.label-schema.vendor="DL7DET <detlef@lampart.de>"
LABEL org.label-schema.name="mikrotik.upgrade.server"
LABEL org.label-schema.url="https://cb3.lampart-web.de/internal/docker-projects/mikrotik-docker-images/mikrotik-alp_rc_upgrade-server" 
LABEL org.label-schema.version=$LINUX_VERSION-$PROD_VERSION 
LABEL org.label-schema.version-prod=$PROD_VERSION 
LABEL org.label-schema.version-devel=$DEVEL_VERSION 
LABEL org.label-schema.build-date=$BUILD 
LABEL org.label-schema.version_alpine_version=$ALPINE_VERSION 
LABEL org.label-schema.vcs-url="https://cb3.lampart-web.de/internal/docker-projects/mikrotik-docker-images/mikrotik-alp_rc_upgrade-server.git" 
LABEL org.label-schema.vcs-ref=$COMMIT_SHA 
LABEL org.label-schema.docker.dockerfile="/Dockerfile" 
LABEL org.label-schema.description="alpine-linux-rc-upgrade-server mus mikrotik.upgrade.server" 
LABEL org.label-schema.usage="https://github.com/felted67/mikrotik-alp_rc_upgrade-server/blob/main/doc/mus-documentation.pdf" 
LABEL org.label-schema.url="https://github.com/felted67/mikrotik-alp_rc_upgrade-server" 
LABEL org.label-schema.schema-version="1.0"

RUN echo 'https://ftp.halifax.rwth-aachen.de/alpine/v3.20/main/' >> /etc/apk/repositories \
    && echo 'https://ftp.halifax.rwth-aachen.de/alpine/v3.20/community' >> /etc/apk/repositories \
    && apk add --no-cache --update --upgrade su-exec ca-certificates

# install sudo as root
RUN apk add --update sudo

# add new user "mikrotik"
RUN adduser -D $USER \
    && mkdir -p /etc/sudoers.d \
    && echo "$USER ALL=(ALL:ALL)  ALL" > /etc/sudoers.d/$USER \
    && chmod 0440 /etc/sudoers.d/$USER

# add new user "apache" to /etc/sudoers.d
RUN echo "$WEBUSER ALL = NOPASSWD: /usr/local/bin/mus-gen-status.sh" > /etc/sudoers.d/$WEBUSER \
    && chmod 0440 /etc/sudoers.d/$WEBUSER

FROM base AS openrc

RUN apk add --no-cache openrc \
    # Disable getty's
    && sed -i 's/^\(tty\d\:\:\)/#\1/g' /etc/inittab \
    && sed -i \
        # Change subsystem type to "docker"
        -e 's/#rc_sys=".*"/rc_sys="docker"/g' \
        # Allow all variables through
        -e 's/#rc_env_allow=".*"/rc_env_allow="\*"/g' \
        # Start crashed services
        -e 's/#rc_crashed_stop=.*/rc_crashed_stop=NO/g' \
        -e 's/#rc_crashed_start=.*/rc_crashed_start=YES/g' \
        # Define extra dependencies for services
        -e 's/#rc_provide=".*"/rc_provide="loopback net"/g' \
        /etc/rc.conf \
    # Remove unnecessary services
    && rm -f /etc/init.d/hwdrivers \
            /etc/init.d/hwclock \
            /etc/init.d/hwdrivers \
            /etc/init.d/modules \
            /etc/init.d/modules-load \
            /etc/init.d/modloop \
    # Can't do cgroups
    && sed -i 's/\tcgroup_add_service/\t#cgroup_add_service/g' /lib/rc/sh/openrc-run.sh \
    && sed -i 's/VSERVER/DOCKER/Ig' /lib/rc/sh/init.sh

RUN apk update && \
    apk add --no-cache openssh mc unzip wget htop
    
RUN apk update && \
    apk --no-cache add apache2 apache2-proxy apache-mod-fcgid tzdata

RUN apk update && \
    apk --no-cache add sed bash bash-doc bash-completion ncurses busybox-suid busybox-openrc rsyslog

COPY ./config_files/auto_init /etc/init.d/
COPY ./config_files/auto_init.sh /sbin/
COPY ./config_files/first_start.sh /sbin/

COPY ./config_files/httpd.new.conf /etc/apache2/
COPY ./config_files/mpm.new.conf /etc/apache2/conf.d/
COPY ./config_files/mus.conf /root/
COPY ./config_files/upgrade.mikrotik.com.conf /root/
COPY ./config_files/status-update.cgi /root/
COPY ./config_files/routeros.raw /root/
COPY ./config_files/winbox3.raw /root/
COPY ./config_files/winbox4.raw /root/
COPY ./config_files/routeros.0.00.conf /root/
COPY ./config_files/CHANGELOG.0.0 /root/
COPY ./config_files/mus-start.sh /root/
COPY ./config_files/mus-start-bg.sh /root/
COPY ./config_files/mus-sync.sh /root/
COPY ./config_files/mus-gen-status.sh /root/
COPY ./config_files/webserver.data.tar.gz /root/
COPY ./config_files/crond /etc/init.d/
COPY ./config_files/crontabs.root.new /root/
COPY ./config_files/mus-cron-job.sh /root/
COPY ./config_files/version.info /root/
COPY ./config_files/motd.new /root/
COPY ./config_files/last_completed.new /root/
COPY ./config_files/error.new /root/
COPY ./doc/mus-documentation.pdf /root/

RUN ["ln", "-s", "/usr/share/zoneinfo/Europe/Berlin", "/etc/localtime"]
RUN ["ln", "-sf", "/opt/mikrotik.upgrade.server/tools/mus-cron-job.sh", "/etc/periodic/daily/run"]
RUN ["mkdir", "-p", "/etc/periodic/2min"]
RUN ["mkdir", "-p", "/etc/periodic/5min"]
RUN chown root:root /etc/init.d/crond && chmod 0775 /etc/init.d/crond
RUN chown root:root /etc/init.d/auto_init && chmod 0755 /etc/init.d/auto_init
RUN chown root:root /sbin/first_start.sh && chmod 0700 /sbin/first_start.sh
RUN chown root:root /sbin/auto_init.sh && chmod 0700 /sbin/auto_init.sh

RUN ln -s /etc/init.d/auto_init /etc/runlevels/default/auto_init

EXPOSE 22/tcp
EXPOSE 80/tcp
# EXPOSE 443/tcp # Preconfigured for (later) https:// access

CMD ["/sbin/init"]

#USER $USER # Change default user - comming release
#WORKDIR $HOME # Change default home-dir - comming release