#!/bin/bash

# Stop the script at the first failure
set -e

echo "DEBUG: Environment of $0"; env; id; echo "END_DEBUG"


# install PBSpro user
PBSPROUSER_HOME=/home/pbsuser
useradd -r -m -U -d $PBSPROUSER_HOME -s /bin/bash -c "PBSpro user" pbsuser

# It seems that non-root users cannot execute anything from /home/travis
# so we copy the whole directory for the pbsuser user
PBSPROUSER_HOME=/home/pbsuser
cp -a /home/travis/build/Ensembl/ensembl-hive-pbspro $PBSPROUSER_HOME
PBSPRO_CHECKOUT_LOCATION=$PBSPROUSER_HOME/ensembl-hive-pbspro
chown -R pbsuser: $PBSPRO_CHECKOUT_LOCATION
HIVE_CHECKOUT_LOCATION=$PBSPRO_CHECKOUT_LOCATION/ensembl-hive

# Install extra packages inside the container
yum install -y epel-release sudo
$HIVE_CHECKOUT_LOCATION/docker/setup_os.CentOS-7.sh
$HIVE_CHECKOUT_LOCATION/docker/setup_cpan.CentOS-7.sh $HIVE_CHECKOUT_LOCATION $PBSPRO_CHECKOUT_LOCATION

$PBSPRO_CHECKOUT_LOCATION/scripts/ensembl-hive-pbspro/start_pbs.sh

sudo -i -u pbsuser $PBSPRO_CHECKOUT_LOCATION/travisci/run_tests.sh

