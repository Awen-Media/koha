FROM debian:buster AS builder

RUN apt-get update && apt-get --no-install-recommends -y install \
    ca-certificates \
    cpanminus \
    default-libmysqlclient-dev \
    gcc \
    gettext \
    git \
    libc6-dev \
    libexpat1-dev \
    libfribidi-dev \
    libgd-dev \
    libxslt1-dev \
    libyaz-dev \
    make \
    perl \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY koha.cpanfile ./cpanfile

RUN export PERL_CPANM_OPT="--quiet --metacpan --notest --local-lib-contained /app/.local" \
    && cpanm --installdeps . \
    && cpanm JSON::Validator@4.05 Mojolicious::Plugin::OpenAPI@3.40 Mojolicious@8 IO::Scalar \
    && cpanm Starman \
    && rm -rf /root/.cpanm

# Invalidate docker cache when there are new commits
#ADD https://api.github.com/repos/Koha-Community/Koha/git/refs/heads/master version.json
#RUN git clone --progress --depth 1 --branch master https://github.com/Koha-Community/Koha.git koha

FROM debian:buster

LABEL maintainer="contacto@awen-media.com"

RUN apt-get update && apt-get --no-install-recommends -y install \
    cron \
    fonts-dejavu \
    gettext \
    libexpat1 \
    libfribidi0 \
    libgd3 \
    libmariadb3 \
    libxslt1.1 \
    libyaz5 \
    locales \
    locales-all \
    nano \
    perl \
    supervisor \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /usr/share/koha
RUN ln -s /home/koha/koha/debian/scripts /usr/share/koha/bin

# Link OPAC files and translator files
RUN mkdir /opac
RUN mkdir /opac/htdocs
RUN mkdir /opac/htdocs/opac-tmpl
#RUN mkdir /opac/htdocs/intranet-tmpl
RUN ln -s /home/koha/koha/koha-tmpl/opac-tmpl /opac/htdocs/opac-tmpl/bootstrap

#/misc/translator/po
RUN ln -s /home/koha/koha/misc/ /misc

# Configure sites
RUN mkdir /etc/koha
RUN mkdir /etc/koha/sites
RUN ln -s /home/koha/etc/koha-conf.xml /etc/koha/koha-conf.xml

RUN adduser --disabled-password --gecos '' koha

USER koha

WORKDIR /home/koha

COPY --from=builder --chown=koha:koha /app .
COPY --chown=koha:koha koha-conf.xml.in etc/
COPY --chown=koha:koha log4perl.conf etc/

#CronJob tasks
COPY koha.crontab.ini /etc/cron.d/koha
RUN crontab /etc/cron.d/koha

#Environment vars used by koha_conf file
ENV KOHA_CONF /home/koha/etc/koha-conf.xml
ENV ZEBRA_CONF_DIR /home/koha/koha/etc/zebradb
ENV PERL5LIB /home/koha/koha:/home/koha/.local/lib/perl5
ENV PATH /home/koha/.local/bin:$PATH
ENV LC_ALL es_MX.UTF-8
ENV LANG es_MX.UTF-8
ENV LANGUAGE es_MX.UTF-8
ENV KOHA_CRON_PATH=/home/koha/koha/misc/cronjobs

EXPOSE 5000 5001

COPY koha-custom.sh /home/koha/libs/koha-custom.sh
COPY docker-entrypoint.sh /usr/local/bin/

WORKDIR /home/koha/koha
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["starman", "--listen", ":5000", "--listen", ":5001"]
