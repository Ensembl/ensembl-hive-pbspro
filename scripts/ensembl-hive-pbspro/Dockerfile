# Dockerfile to build a PBSpro-enabled container with extra packages needed to
# run and test eHive

# Cloned and updated version of the official pbspro image
FROM pbspro/pbspro

# Proc::Daemon trick: we need version 0.23 but only version 0.19 is in the
# centos archives. cpanm will fail building 0.23 if 0.19 is around, so we
# need to build 0.23 before we install anything else
RUN yum install -y perl-App-cpanminus perl-Test-Simple perl-Proc-ProcessTable
RUN echo "requires 'Proc::Daemon', '0.23';" > /root/cpanfile
RUN cpanm --installdeps --notest --with-recommends /root/

# install required extra software
RUN yum install -y curl git \
                   sqlite perl-DBD-SQLite postgresql perl-DBD-Pg mariadb perl-DBD-MySQL perl-DBI \
                   perl-Capture-Tiny perl-DateTime perl-Time-Piece perl-HTML-Parser perl-JSON \
                   perl-Test-Exception perl-Test-Simple perl-Test-Warn perl-Test-Warnings perl-Test-File-Contents perl-Test-Perl-Critic perl-GraphViz \
                   gnuplot perl-BSD-Resource

# install PBSpro user
RUN sed -i "s/^\%wheel\s\+ALL=(ALL)\s\+ALL/%wheel ALL=(ALL) NOPASSWD:ALL/" /etc/sudoers
RUN useradd -r -m -U -G wheel -d /home/pbsuser -s /bin/bash -c "PBSpro user" pbsuser


RUN mkdir /repo \
    && git clone -b master https://github.com/Ensembl/ensembl-hive.git /repo/ensembl-hive \
    && git clone -b master https://github.com/Ensembl/ensembl-hive-pbspro.git /repo/ensembl-hive-pbspro


RUN cpanm --installdeps --with-recommends /repo/ensembl-hive \
    && cpanm --installdeps --with-recommends /repo/ensembl-hive-pbspro

ENV EHIVE_ROOT_DIR "/repo/ensembl-hive"
ENV PATH "/repo/ensembl-hive/scripts:$PATH"
ENV PERL5LIB "/repo/ensembl-hive/modules:/repo/ensembl-hive-pbspro/modules:$PERL5LIB"
ENV EHIVE_TEST_PIPELINE_URLS "sqlite:////home/pbsuser/"
ENV EHIVE_MEADOW_TO_TEST "PBSPro"

COPY start_pbs_and_login.sh /root/
RUN chmod +x /root/start_pbs_and_login.sh

# Wrapper that first starts PBS before running the command
ENTRYPOINT ["/root/start_pbs_and_login.sh"]
# Default command is a shell
CMD ["/bin/bash"]

