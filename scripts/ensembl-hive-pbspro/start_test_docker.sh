#!/bin/bash

HIVE_PBSPRO_LOCATION=$1
EHIVE_LOCATION=$2
DOCKER_NAME=${3:-ensemblorg/ensembl-hive-pbspro}

echo "!!!!!!!!!!!!!!"
echo "! To test the PBSPro meadow, run: prove -v '/repo/ensembl-hive/t/04.meadow/meadow-longmult.mt'"
echo "!!!!!!!!!!!!!!"
echo

exec docker run -it -v "$EHIVE_LOCATION:/repo/ensembl-hive" -v "$HIVE_PBSPRO_LOCATION:/repo/ensembl-hive-pbspro" "$DOCKER_NAME"

