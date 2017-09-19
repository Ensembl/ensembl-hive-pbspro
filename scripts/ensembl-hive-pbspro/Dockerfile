# Dockerfile to build a PBSpro-enabled container with extra packages needed to
# run and test eHive

# Cloned and updated version of the official pbspro image
FROM pbspro/pbspro

# Install essential things
RUN yum install -y epel-release sudo git \
    && sed -i "s/^\%wheel\s\+ALL=(ALL)\s\+ALL/%wheel ALL=(ALL) NOPASSWD:ALL/" /etc/sudoers \
    && useradd -r -m -U -G wheel -d /home/pbsuser -s /bin/bash -c "PBSpro user" pbsuser

# Clone the repos
RUN mkdir /repo \
    && git clone -b master https://github.com/Ensembl/ensembl-hive.git /repo/ensembl-hive \
    && git clone -b master https://github.com/Ensembl/ensembl-hive-pbspro.git /repo/ensembl-hive-pbspro

# Install all the dependencies
RUN /repo/ensembl-hive/docker/setup_os.CentOS-7.sh \
    && /repo/ensembl-hive/docker/setup_cpan.CentOS-7.sh /repo/ensembl-hive /repo/ensembl-hive-pbspro

ENV EHIVE_ROOT_DIR "/repo/ensembl-hive"
ENV PATH "/repo/ensembl-hive/scripts:$PATH"
ENV PERL5LIB "/repo/ensembl-hive/modules:/repo/ensembl-hive-pbspro/modules:$PERL5LIB"
ENV EHIVE_TEST_PIPELINE_URLS "sqlite:////home/pbsuser/"
ENV EHIVE_MEADOW_TO_TEST "PBSPro"

# Wrapper that first starts PBS before running the command
ENTRYPOINT ["/repo/ensembl-hive-pbspro/scripts/ensembl-hive-pbspro/start_pbs_and_login.sh"]
# Default command is a shell
CMD ["/bin/bash"]

