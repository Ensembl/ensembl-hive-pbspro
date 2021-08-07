
PBSpro Meadow for eHive
=======================

[![Build Status](https://travis-ci.org/Ensembl/ensembl-hive-pbspro.svg?branch=version/2.6)](https://travis-ci.org/Ensembl/ensembl-hive-pbspro)

[eHive](https://github.com/Ensembl/ensembl-hive) is a system for running computation pipelines on distributed computing resources - clusters, farms or grids.
This repository is the implementation of eHive's _Meadow_ interface for the [PBSpro](https://research.cs.wisc.edu/pbspro/) job scheduler.


Version numbering and compatibility
-----------------------------------

This repository is versioned the same way as eHive itself, and both
checkouts are expected to be on the same branch name to function properly.
* `version/2.5` is a stable branch that works with eHive's `version/2.5`
  branch.
* `version/2.6` is a stable branch that works with eHive's `version/2.6`
  branch. Both branches are _stable_ and _only_ receive bugfixes.
* `master` is the development branch and follows eHive's `master`. We
  primarily maintain eHive, so both repos may sometimes go out of sync
  until we upgrade the PBSpro module too


Testing the PBSpro meadow
-------------------------

The module is continuously tested under the PBSpro version shipped by
PBSpro themselves in the Docker image [pbspro/pbspro](https://hub.docker.com/r/pbspro/pbspro/)
(18.1.0 as of March 2018).

We provide a Docker image
[ensemblorg/ensembl-hive-pbspro](https://hub.docker.com/r/ensemblorg/ensembl-hive-pbspro/),
which contains all the dependencies and checkouts.

To test your own version of the code, you can use
`scripts/ensembl-hive-pbspro/start_test_docker.sh`,
but first edit the location of the code you want to test.
The script will start a new ``ensemblorg/ensembl-hive-pbspro`` container with
your own copies of ensembl-hive and ensembl-hive-pbspro mounted.

```
scripts/ensembl-hive-pbspro/start_test_docker.sh /path/to/your/ensembl-hive /path/to/your/ensembl-hive-pbspro name_of_docker_image
prove -v '/repo/ensembl-hive/t/04.meadow/meadow-longmult.mt   # in the container

```

The last argument can be skipped and defaults to `ensemblorg/ensembl-hive-pbspro`.

Contributors
------------

This module has been written by [Leo Gordon](https://github.com/ens-lg4)
(EMBL-EBI) with feedback from Avik Datta (Imperial College London). 
[Matthieu Muffato](https://github.com/muffato) (EMBL-EBI) has then added
the Docker layers.


Contact us
----------

eHive is maintained by the [Ensembl](http://www.ensembl.org/info/about/) project.
We (Ensembl) are only using Platform LSF to run our computation
pipelines, and can only test PBSpro on the Docker image indicated above.

There is eHive users' mailing list for questions, suggestions, discussions and announcements.
To subscribe to it please visit [this link](http://listserver.ebi.ac.uk/mailman/listinfo/ehive-users)

