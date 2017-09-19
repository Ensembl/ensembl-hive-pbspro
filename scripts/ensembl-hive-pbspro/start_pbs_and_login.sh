#!/bin/bash

"$(dirname "$0")/start_pbs.sh" && exec sudo -E -u pbsuser "PERL5LIB=$PERL5LIB" "PATH=$EHIVE_ROOT_DIR/scripts:/sbin:/bin:/usr/sbin:/usr/bin:/opt/pbs/bin" "$@"

