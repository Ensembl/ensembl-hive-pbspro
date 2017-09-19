#!/bin/bash

set -e

# Update the config with the container's hostname
sed -i "s/^PBS_SERVER=.*\$/PBS_SERVER=$(hostname)/" /etc/pbs.conf
sed -i 's/PBS_START_MOM=0/PBS_START_MOM=1/' /etc/pbs.conf
echo "\$clienthost $(hostname)" > /var/spool/pbs/mom_priv/config
#/opt/pbs/bin/qmgr -c "create node $(hostname)"

/etc/init.d/pbs start

