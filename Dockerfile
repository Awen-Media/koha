FROM ubuntu:20.04

ENV KOHA_RELEASE 20.05
ENV SERVER_TZ America/Mexico_City
ENV LC_ALL es_MX.UTF-8
ENV LANG es_MX.UTF-8
ENV LANGUAGE es_MX.UTF-8

# Koha variabales
ENV KOHA_LANGS es-ES
ENV KOHA_INSTANCE awen
ENV MYSQL_DATABASE koha_awen
ENV MYSQL_HOST db
ENV MYSQL_PORT 3306
ENV MYSQL_USER root
ENV MYSQL_PASSWORD root
ENV MEMCACHED_SERVER memcached:11211
ENV MEMCACHED_NAMESPACE KOHA
ENV ZEBRA_LANGUAGE es
ENV KOHA_ZEBRAUSER zebrauser
ENV KOHA_ZEBRAPASS lkjasdpoiqrr
ENV KOHA_DBHOST db
ENV KOHA_ADMINUSER root
ENV KOHA_ADMINPASS root
ENV KOHA_HOME /usr/share/koha
ENV ELASTICSEARCH_SERVER elasticsearch:9200

# Config /etc/koha/koha-sites.conf
ENV DOMAIN .local
ENV INTRAPORT 8080
ENV INTRAPREFIX ""
ENV INTRASUFFIX -intra
ENV OPACPORT 80
ENV OPACPREFIX ""
ENV OPACSUFFIX ""

# Configure TZ
RUN DEBIAN_FRONTEND="noninteractive" apt-get update && apt-get -y install tzdata
RUN echo $SERVER_TZ | tee /etc/timezone
RUN dpkg-reconfigure --frontend noninteractive tzdata

# Install dependencies
RUN apt-get update \
    && apt-get install -y \
    ca-certificates \
    default-libmysqlclient-dev \
    gnupg \
    gnupg1 \
    gnupg2 \
    locales \
    locales-all \
    lsb-release \
    nano \
    nmap \ 
    netcat \
    libswitch-perl \
    libnet-ssleay-perl \ 
    libcrypt-ssleay-perl \ 
    apache2 \
    supervisor \ 
    inetutils-syslogd \
    software-properties-common \
    iputils-ping \
    wget

# Missing perl dependencies
RUN apt-get update && apt-get install -y \
    libhtml-strip-perl libipc-run3-perl paps \
    libdancer-perl libobject-tiny-perl libxml-libxml-simple-perl libconfig-merge-perl \
    libyaml-libyaml-perl \
    libmojolicious-plugin-openapi-perl

# Configure and Install Koha Common
RUN wget -q -O- https://debian.koha-community.org/koha/gpg.asc | apt-key add -  \
    && apt-get update

RUN echo 'deb http://debian.koha-community.org/koha 20.05 main' | tee /etc/apt/sources.list.d/koha.list

RUN DEBIAN_FRONTEND="noninteractive" apt-get update && apt-get install -y koha-common

# Setup apache
RUN sed -i 's/Listen 80/Listen 80\nListen 8080\n/g' /etc/apache2/ports.conf \
    && a2dissite 000-default \
    && a2enmod rewrite \
    && a2enmod cgi \
    && a2enmod headers \
    && a2enmod proxy_http \
    && a2enmod remoteip \
    && service apache2 restart

# Update koha-sites configuration
RUN sed -i 's/DOMAIN=".myDNSname.org"/DOMAIN="${DOMAIN}"/g' /etc/koha/koha-sites.conf
RUN sed -i 's/INTRAPORT="80"/INTRAPORT="${INTRAPORT}"/g' /etc/koha/koha-sites.conf
RUN sed -i 's/INTRAPREFIX=""/INTRAPREFIX="${INTRAPREFIX}"/g' /etc/koha/koha-sites.conf
RUN sed -i 's/INTRASUFFIX="-intra"/INTRASUFFIX="${INTRASUFFIX}"/g' /etc/koha/koha-sites.conf
RUN sed -i 's/OPACPORT="80"/OPACPORT="${OPACPORT}"/g' /etc/koha/koha-sites.conf
RUN sed -i 's/OPACPREFIX=""/OPACPREFIX="${OPACPREFIX}"/g' /etc/koha/koha-sites.conf
RUN sed -i 's/OPACSUFFIX=""/OPACSUFFIX="${OPACSUFFIX}"/g' /etc/koha/koha-sites.conf
RUN sed -i 's/MEMCACHED_SERVERS="127.0.0.1:11211"/MEMCACHED_SERVERS="${MEMCACHED_SERVER}"/g' /etc/koha/koha-sites.conf
RUN sed -i 's/ZEBRA_LANGUAGE="en"/ZEBRA_LANGUAGE="${ZEBRA_LANGUAGE}"/g' /etc/koha/koha-sites.conf

# Update DB configuration
RUN echo "[client]\nhost=$MYSQL_HOST\nuser=$MYSQL_USER\npassword=$MYSQL_PASSWORD" >> /etc/mysql/koha-common.cnf

# Script and deps for checking if koha is up & ready (to be executed using docker exec)
COPY docker-wait_until_ready.py /root/wait_until_ready.py

# NCIP Server and dependencies
ADD ./files/NCIPServer /NCIPServer

# Installer files
COPY ./files/installer /installer

# Templates
COPY ./files/templates /templates

# Cronjobs
COPY ./files/cronjobs /cronjobs

# CAS bug workaround
ADD ./files/Authen_CAS_Client_Response_Failure.pm /usr/share/perl5/Authen/CAS/Client/Response/Failure.pm
ADD ./files/Authen_CAS_Client_Response_Success.pm /usr/share/perl5/Authen/CAS/Client/Response/Success.pm

# CAS bug workaround
ADD ./files/Authen_CAS_Client_Response_Failure.pm /usr/share/perl5/Authen/CAS/Client/Response/Failure.pm
ADD ./files/Authen_CAS_Client_Response_Success.pm /usr/share/perl5/Authen/CAS/Client/Response/Success.pm

ENV HOME /root
WORKDIR /root

COPY ./files/logrotate.config /etc/logrotate.d/syslog.conf
COPY ./files/syslog.config /etc/syslog.conf

# Cronjob for sending print notices to print service
# COPY ./files/cronjobs/brevdue.pl /usr/share/koha/bin/cronjobs/brevdue.pl
# RUN chmod 0755 /usr/share/koha/bin/cronjobs/brevdue.pl

# Override nightly and hourly run koha cron jobs
COPY ./files/cronjobs/daily-koha-common /etc/cron.daily/koha-common
RUN chmod 0755 /etc/cron.daily/koha-common && rm -rf /etc/cron.hourly/koha-common

EXPOSE 80 8080 3000
COPY docker-entrypoint.sh /root/entrypoint.sh
ENTRYPOINT ["/root/entrypoint.sh"]
