#!/bin/bash
set -e

echo "Global config ..."
#envsubst < /templates/global/koha-sites.conf.tmpl > /etc/koha/koha-sites.conf
envsubst < /templates/global/passwd.tmpl > /etc/koha/passwd

echo "Setting up local cronjobs ..."
#envsubst < /cronjobs/deichman-koha-common.tmpl > /etc/cron.d/deichman-koha-common
envsubst < /cronjobs/koha-common.tmpl > /etc/cron.d/koha-common
#chmod 644 /etc/cron.d/deichman-koha-common

echo "Setting up supervisord ..."
envsubst < /templates/global/supervisord.conf.tmpl > /etc/supervisor/conf.d/supervisord.conf

echo "Mysql server setup ..."
if [ "$MYSQL_HOST" != "localhost" ]; then
  printf "Using linked mysql container $MYSQL_HOST\n"
  if ! ping -c 1 -W 1 $MYSQL_HOST; then
    echo "ERROR: Could not connect to remote mysql $MYSQL_HOST"
    exit 1
  fi
else
  printf "No linked mysql or unable to connect to linked mysql $MYSQL_HOST\n-- initializing local mysql ...\n"
  # overlayfs fix for mysql
  find /var/lib/mysql -type f -exec touch {} \;
  /etc/init.d/mysql start
  sleep 1 # waiting for mysql to spin up on slow computers
  echo "127.0.0.1  $MYSQL_HOST" >> /etc/hosts
  echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' ; \
        CREATE USER '$MYSQL_USER'@'$MYSQL_HOST' IDENTIFIED BY '$MYSQL_PASSWORD' ; \
        CREATE DATABASE IF NOT EXISTS koha_$KOHA_INSTANCE ; \
        GRANT ALL ON koha_$KOHA_INSTANCE.* TO '$MYSQL_USER'@'%' WITH GRANT OPTION ; \
        GRANT ALL ON koha_$KOHA_INSTANCE.* TO '$MYSQL_USER'@'$MYSQL_HOST' WITH GRANT OPTION ; \
        FLUSH PRIVILEGES ;" | mysql -u root -p$MYSQL_PASSWORD
fi

echo "Initializing local instance ..."
envsubst < /templates/instance/koha-common.cnf.tmpl > /etc/mysql/koha-common.cnf
koha-create --request-db $KOHA_INSTANCE || true
koha-create --populate-db $KOHA_INSTANCE

echo "Configuring local instance ..."
envsubst < /templates/instance/koha-conf.xml.tmpl > /etc/koha/sites/$KOHA_INSTANCE/koha-conf.xml
envsubst < /templates/instance/log4perl.conf.tmpl > /etc/koha/sites/$KOHA_INSTANCE/log4perl.conf
envsubst < /templates/instance/zebra.passwd.tmpl > /etc/koha/sites/$KOHA_INSTANCE/zebra.passwd

envsubst < /templates/instance/apache.tmpl > /etc/apache2/sites-available/$KOHA_INSTANCE.conf

echo "Configuring SIPconfig.xml from templates and data from csv ..."
door=`awk -f /templates/instance/SIPconfig.template_account_dooraccess.awk /templates/instance/SIPconfig.dooraccess.csv` ; \
logins=`awk -f /templates/instance/SIPconfig.template_account.awk /templates/instance/SIPconfig.logins.csv` ; \
inst=`awk -f /templates/instance/SIPconfig.template_institution.awk /templates/instance/SIPconfig.institutions.csv` ; \
awk -v door="$door" -v logins="$logins" -v inst="$inst" \
  '{gsub(/__TEMPLATE_DOOR_ACCOUNTS__/, door); gsub(/__TEMPLATE_LOGIN_ACCOUNTS__/, logins); gsub(/__TEMPLATE_INSTITUTIONS__/, inst) };1' \
  /templates/instance/SIPconfig.xml.tmpl | envsubst > /etc/koha/sites/$KOHA_INSTANCE/SIPconfig.xml

echo "Configuring languages ..."
# Install languages in Koha
for language in $KOHA_LANGS
do
    koha-translate --install $language
done

ln -sf /usr/share/koha/api /api
chmod 777 /var/log/koha/awen/opac-error.log
chmod 777 /var/log/koha/awen/intranet-error.log

echo "Restarting apache to activate local changes..."
service apache2 restart

sleep 1 # waiting for apache restart to finish
#echo "Running db installer and applying local deichman mods - please be patient ..."
#cd /usr/share/koha/lib && /installer/installer.sh

#echo "Fixing bug in translated member search template in Norwegian..."
#sed -i 's/l\xc3\xa5nenummer/borrowernumber/' /usr/share/koha/intranet/htdocs/intranet-tmpl/prog/nb-NO/modules/members/tables/members_results.tt || true

echo "Enabling plack ..."
koha-plack --enable "$KOHA_INSTANCE"

echo "Installation finished - Stopping all services and giving supervisord control ..."
service apache2 stop
koha-indexer --stop "$KOHA_INSTANCE"
koha-stop-zebra "$KOHA_INSTANCE"

supervisord -c /etc/supervisor/conf.d/supervisord.conf