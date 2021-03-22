#!/bin/bash

#set -e

export MYSQL_HOST=${MYSQL_HOST:-db}
export MYSQL_PORT=${MYSQL_PORT:-3306}
export MYSQL_DATABASE=${MYSQL_DATABASE:-koha}
export MYSQL_USER=${MYSQL_USER:-koha}
export MYSQL_PASSWORD=${MYSQL_PASSWORD:-koha}
export MEMCACHED_SERVER=${MEMCACHED_SERVER:-memcached:11211}
export MEMCACHED_SERVERS=${MEMCACHED_SERVER:-memcached:11211}
export MEMCACHED_NAMESPACE=${MEMCACHED_NAMESPACE:-KOHA}
export ELASTICSEARCH_SERVER=${ELASTICSEARCH_SERVER:-elasticsearch:9200}
export ELASTICSEARCH_INDEX_NAME=${ELASTICSEARCH_INDEX_NAME:-koha}
export PATH=$PATH:/usr/share/koha/bin
source /home/koha/libs/koha-custom.sh

# Create config file from koha_conf_in template, replacing values
# with env vars
koha_create_custom_config "$KOHA_CONF" "$KOHA_CONF.in"

# Koha languages
koha_install_language "${KOHA_LANGS}"

exec "$@"
