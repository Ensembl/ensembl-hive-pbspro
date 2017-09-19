#!/bin/bash

# Stop the script at the first failure
set -e

echo "DEBUG: Environment of $0"; env; id; echo "END_DEBUG"

# Proc::Daemon trick: we need version 0.23 but only version 0.19 is in the
# centos archives. cpanm will fail building 0.23 if 0.19 is around, so we
# need to build 0.23 before we install anything else
yum install -y perl-App-cpanminus perl-Test-Simple perl-Proc-ProcessTable
echo "requires 'Proc::Daemon', '0.23';" > /root/cpanfile
cpanm --installdeps --notest --with-recommends /root/

# install required extra software
yum install -y curl git \
                   sqlite perl-DBD-SQLite postgresql perl-DBD-Pg mariadb perl-DBD-MySQL perl-DBI \
                   perl-Capture-Tiny perl-DateTime perl-Time-Piece perl-HTML-Parser perl-JSON \
                   perl-Test-Exception perl-Test-Simple perl-Test-Warn perl-Test-Warnings perl-Test-File-Contents perl-Test-Perl-Critic perl-GraphViz \
                   gnuplot perl-BSD-Resource

# install PBSpro user
sed -i "s/^\%wheel\s\+ALL=(ALL)\s\+ALL/%wheel ALL=(ALL) NOPASSWD:ALL/" /etc/sudoers
useradd -r -m -U -G wheel -d /home/pbsuser -s /bin/bash -c "PBSpro user" pbsuser

# It seems that non-root users cannot execute anything from /home/travis
# so we copy the whole directory for the pbsuser user
PBSPROADMIN_HOME=/home/pbsuser
cp -a /home/travis/build/Ensembl/ensembl-hive-pbspro $PBSPROADMIN_HOME
PBSPRO_CHECKOUT_LOCATION=$PBSPROADMIN_HOME/ensembl-hive-pbspro
chown -R pbsuser: $PBSPRO_CHECKOUT_LOCATION

# There are no packages for GetOpt::ArgvFile and Chart::Gnuplot, so we need
# to use cpanm again
cpanm --installdeps --with-recommends $PBSPRO_CHECKOUT_LOCATION/ensembl-hive
cpanm --installdeps --with-recommends $PBSPRO_CHECKOUT_LOCATION

sudo --login -u pbsuser $PBSPRO_CHECKOUT_LOCATION/travisci/run_tests.sh

