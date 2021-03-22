#!/bin/bash

# koha_install_language
# Install custom language in the Koha Site (include intranet and opac)
# koha_install_language "es-ES"
koha_install_language()
{
    local koha_langs=$1
    if [ "${koha_langs}" != 0 ]
    then
        echo "Installing languages"
        LANGS=$(koha-translate -l)
        for i in $koha_langs
        do
            if ! echo "${LANGS}"|grep -q -w $i
            then
                echo "Installing language $i"
                koha-translate -i $i
            else
                echo "Language $i already present"
            fi
        done
    fi
}

# koha_create_custom_config
# Create config file from koha_conf_in template, replacing values with env vars
# koha_create_custom_config "/home/koha/etc/koha-conf.xml" "/home/koha/etc/koha-conf.xml.in"
koha_create_custom_config()
{
    local koha_conf=$1
    local koha_conf_in=$2
    
    if [ -r "$koha_conf_in" ]; then
        envsubst < "$koha_conf_in" > "$KOHA_CONF" \
            && rm -f "$koha_conf_in"
        echo "koha_conf has been updated with koha_conf_in with env vars replaced"
    else
        echo "koha_conf_in not exists in the path provided"
    fi
}