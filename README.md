
PBSpro Meadow for eHive
=======================

[![Build Status](https://travis-ci.org/Ensembl/ensembl-hive-pbspro.svg?branch=master)](https://travis-ci.org/Ensembl/ensembl-hive-pbspro)

[eHive](https://github.com/Ensembl/ensembl-hive) is a system for running computation pipelines on distributed computing resources - clusters, farms or grids.
This repository is the implementation of eHive's _Meadow_ interface for the [PBSpro](https://research.cs.wisc.edu/pbspro/) job scheduler.


Version numbering and compatibility
-----------------------------------

This repository is versioned the same way as eHive itself, and both
checkouts are expected to be on the same branch name to function properly.
* `master` is the development branch and follows eHive's `master`. We
  primarily maintain eHive, so both repos may sometimes go out of sync
  until we upgrade the PBSpro module too
When future stable versions of eHive will be released (named `version/2.5`
etc) we'll create such branches here as well.


Testing the PBSpro meadow
-------------------------

The module is continuously tested under the PBSpro version shipped by
PBSpro themselves in the Docker image [pbspro/pbspro](https://hub.docker.com/r/pbspro/pbspro/)
(17.1.0 as of September 2017).

We provide a Docker image
[ensemblorg/ensembl-hive-pbspro](https://hub.docker.com/r/ensemblorg/ensembl-hive-pbspro/),
which contains all the dependencies and checkouts.

To build the latter, you first need to edit the `HIVE_PBSPRO_LOCATION` and
`EHIVE_LOCATION` variables in
`scripts/docker-ehive-pbspro-test/Dockerfile`.
The configuration assumes that you have existing checkouts of both
ensembl-hive and ensembl-hive-pbspro on the host (somewhere under your
home directory), and shares the host filesystem with the container.

```
docker run -it ensemblorg/ensembl-hive-pbspro  # run as normal user on your machine. Will start the image as pbsuser
prove -rv ensembl-hive-pbspro/t                # run as "pbsuser" on the image. Uses sqlite
```

To test your own version of the code, you can use
`scripts/ensembl-hive-pbspro/start_test_docker.sh`.
The scriptwill start a new ``ensemblorg/ensembl-hive-pbspro`` container with
your own copies of ensembl-hive and ensembl-hive-pbspro mounted.

```
scripts/ensembl-hive-pbspro/start_test_docker.sh /path/to/your/ensembl-hive /path/to/your/ensembl-hive-pbspro name_of_docker_image

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

