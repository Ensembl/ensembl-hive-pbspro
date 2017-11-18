#!/bin/bash

# Stop the script at the first failure
set -e

echo "DEBUG: Environment of $0"; env; id; echo "END_DEBUG"

# It seems that non-root users cannot execute anything from /home/travis
# so we copy the whole directory for the pbsuser user
PBSPROUSER_HOME=/home/pbsuser
cp -a /home/travis/build/Ensembl/ensembl-hive-pbspro $PBSPROUSER_HOME
PBSPRO_CHECKOUT_LOCATION=$PBSPROUSER_HOME/ensembl-hive-pbspro
chown -R pbsuser: $PBSPRO_CHECKOUT_LOCATION
HIVE_CHECKOUT_LOCATION=$PBSPRO_CHECKOUT_LOCATION/ensembl-hive

# Install extra packages inside the container
$HIVE_CHECKOUT_LOCATION/docker/setup_cpan.CentOS-7.sh $PBSPRO_CHECKOUT_LOCATION

$PBSPRO_CHECKOUT_LOCATION/scripts/ensembl-hive-pbspro/start_pbs.sh

sudo -i -u pbsuser $PBSPRO_CHECKOUT_LOCATION/travisci/run_tests.sh

