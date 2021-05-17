# koha-docker

This repo contains a docker image to setup koha as container. Also includes a docker-compose integration.

## Configuration

Before to run a container, you need to create a .env file like a next (or check the env.sample file in this repo).

    #Container configuration
    SERVER_TZ=America/Mexico_City
    LC_ALL=es_MX.UTF-8
    LANG=es_MX.UTF-8
    LANGUAGE=es_MX.UTF-8

    #Koha configuration
    KOHA_RELEASE=20.05
    KOHA_LANGS=es-ES
    KOHA_INSTANCE=awen
    MYSQL_DATABASE=koha_awen
    MYSQL_HOST=db
    MYSQL_PORT=3306
    MYSQL_USER=root
    MYSQL_PASSWORD=root
    MEMCACHED_SERVER=memcached:11211
    MEMCACHED_NAMESPACE=KOHA
    ZEBRA_LANGUAGE=es
    ELASTICSEARCH_SERVER=elasticsearch:9200

    # Config /etc/koha/koha-sites.conf
    DOMAIN=.local
    INTRAPORT=8080
    INTRAPREFIX=
    INTRASUFFIX=-intra
    OPACPORT=80
    OPACPREFIX=
    OPACSUFFIX=

## Usage

Run container use the command below:

    docker run -d --cap-add=SYS_NICE --cap-add=DAC_READ_SEARCH -p 80:80 -p 8080:8080 --name koha quantumobject/docker-koha

note: koha used  Apache/mpm itk that create some problem under docker, there are some sites that recommend to add this to pre-view command :   --cap-add=SYS_NICE --cap-add=DAC_READ_SEARCH
