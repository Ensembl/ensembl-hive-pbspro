#!/bin/bash

# Stop the script at the first failure
set -e

echo "DEBUG: Environment of $0"; env; id; echo "END_DEBUG"

# It seems that non-root users cannot execute anything from /home/travis
# so we copy the whole directory for the pbsuser user
PBSPRO_CHECKOUT_LOCATION=/repo/ensembl-hive-pbspro
rm -rf $PBSPRO_CHECKOUT_LOCATION
cp -a /home/travis/build/Ensembl/ensembl-hive-pbspro $PBSPRO_CHECKOUT_LOCATION
chown -R pbsuser: $PBSPRO_CHECKOUT_LOCATION

# Install extra packages inside the container
$EHIVE_ROOT_DIR/docker/setup_cpan.CentOS-7.sh $PBSPRO_CHECKOUT_LOCATION

sudo -i -u pbsuser $PBSPRO_CHECKOUT_LOCATION/travisci/run_tests.sh

