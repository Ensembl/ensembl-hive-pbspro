#!/bin/bash

## This script runs as a normal user (pbsuser) because the default
## configuration of PBSPro does not allow root to submit any jobs

# Stop the script at the first failure
set -e

echo "DEBUG: Environment of $0"; env; id; echo "END_DEBUG"

REPO_HOME=/repo
export EHIVE_ROOT_DIR=$REPO_HOME/ensembl-hive
export PERL5LIB=$EHIVE_ROOT_DIR/modules:$REPO_HOME/ensembl-hive-pbspro/modules
export EHIVE_TEST_PIPELINE_URLS="sqlite:///$HOME/ehive_test_pipeline_db"
export EHIVE_MEADOW_TO_TEST=PBSPro

prove -rv --ext .t --ext .mt "$EHIVE_ROOT_DIR/t/04.meadow/meadow-longmult.mt"

