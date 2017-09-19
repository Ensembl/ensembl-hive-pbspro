#!/bin/bash

HIVE_PBSPRO_LOCATION=$1
EHIVE_LOCATION=$2
DOCKER_NAME=${3:-ensemblorg/ensembl-hive-pbspro}

exec docker run -it -v "$EHIVE_LOCATION:/repo/ensembl-hive" -v "$HIVE_PBSPRO_LOCATION:/repo/ensembl-hive-pbspro" "$DOCKER_NAME"

