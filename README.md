# koha-docker

This repo contains a docker image to setup koha as container. Also includes a docker-compose integration.

## Usage

Run container use the command below:

    docker run -d --cap-add=SYS_NICE --cap-add=DAC_READ_SEARCH -p 80:80 -p 8080:8080 --name koha quantumobject/docker-koha

note: koha used  Apache/mpm itk that create some problem under docker, there are some sites that recommend to add this to pre-view command :   --cap-add=SYS_NICE --cap-add=DAC_READ_SEARCH
