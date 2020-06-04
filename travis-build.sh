#!/usr/bin/env bash

#### halt script on error
set -xe

echo '##### Print docker version'
docker --version

echo '##### Print environment'
env | sort
exit
#### Build the Docker Images
if [ -n "${PHP_VERSION}" ]; then
    cp env-example .env
    sed -i -- "s/PHP_VERSION=.*/PHP_VERSION=${PHP_VERSION}/g" .env
    sed -i -- 's/=false/=true/g' .env
    sed -i -- 's/PHPDBG=true/PHPDBG=false/g' .env
    if [ "${PHP_VERSION}" == "5.6" ]; then
        sed -i -- 's/^AEROSPIKE_PHP_REPOSITORY=/##AEROSPIKE_PHP_REPOSITORY=/g' .env
        sed -i -- 's/^# AEROSPIKE_PHP_REPOSITORY=/AEROSPIKE_PHP_REPOSITORY=/g' .env
    fi
    cat .env
    docker-compose build ${BUILD_SERVICE}
    docker images
fi


