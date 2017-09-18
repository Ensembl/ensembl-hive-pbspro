=pod 

=head1 NAME

    Bio::EnsEMBL::Hive::Meadow::PBSPro

=head1 DESCRIPTION

    This is the 'PBS Pro' implementation of Meadow

=head1 LICENSE

    Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
    Copyright [2016-2017] EMBL-European Bioinformatics Institute

    Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

         http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software distributed under the License
    is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and limitations under the License.

=head1 CONTACT

    Please subscribe to the Hive mailing list:  http://listserver.ebi.ac.uk/mailman/listinfo/ehive-users  to discuss Hive-related questions or to be notified of our updates

=cut


package Bio::EnsEMBL::Hive::Meadow::PBSPro;

use strict;
use warnings;
use Time::Piece;
use Time::Seconds;

use Bio::EnsEMBL::Hive::Utils ('split_for_bash');

use base ('Bio::EnsEMBL::Hive::Meadow');


our $VERSION = '5.1';       # Semantic version of the Meadow interface:
                            #   change the Major version whenever an incompatible change is introduced,
                            #   change the Minor version whenever the interface is extended, but compatibility is retained.


sub name {  # also called to check for availability; assume PBSPro is available if PBSPro server name can be established
    my $mcni = 'Server:';
    my $cmd = "qstat -B -f 2>/dev/null | grep '$mcni'";

#    warn "PBSPro() running cmd:\n\t$cmd\n";

    if(my $name = `$cmd`) {         # note that at least in some installations 'qsub' is not directly runnable on execution nodes (maybe just a PATH issue)
        $name=~/^$mcni\s+(\S+)/;
        return $1;
    } elsif(($ENV{'PBS_JOBID'}//'')=~/^\d+(?:\[\d+\])?\.(\w+)$/) {      # so this is how we check whether we have been submitted under PBSPro
        return $1;
    } else {
        return undef;
    }
}


sub get_current_worker_process_id {
    my ($self) = @_;

    my $pbs_jobid    = $ENV{'PBS_JOBID'};	# looks like this: 4656762.wlm01 or 4699393[4].wlm01 (where wlm01 is the server/cluster name)

    if(defined($pbs_jobid)) {
        return $pbs_jobid;
    } else {
        die "Could not establish the process_id";
    }
}


sub deregister_local_process {
    my ($self) = @_;

    delete $ENV{'PBS_JOBID'};
}


sub status_of_all_our_workers { # returns an arrayref
    my $self                        = shift @_;
    my $meadow_users_of_interest    = shift @_;

    $meadow_users_of_interest = [ '*' ] unless ($meadow_users_of_interest && scalar(@$meadow_users_of_interest));

    my $jnp = $self->job_name_prefix();

    my @status_list = ();

    foreach my $meadow_user (@$meadow_users_of_interest) {
        my $user_part   = ($meadow_user eq '*') ? '' : "-u $meadow_user";

if(0) {     # The -f (full) format potentially gives more information, but generating and parsing it may be expensive.
            # It's off, but keeping it around for future reference.

        my $cmd = "qstat -xtf $user_part";

#        warn "PBSPro::status_of_all_our_workers() running cmd:\n\t$cmd\n";

        my %mpid_attrib = ();
        my ($current_mpid, $index_only, $current_attrib);

        open(my $qstat_fh, '-|', $cmd);

        for my $line (<$qstat_fh>) {
            chomp $line;

            if($line=~/^Job Id: (\w+(\[\d*\])?\.\w+)/) {
                $current_mpid = $1;
                $index_only = $2;
            } elsif($line=~/^\ {4}(\w+) = (.*)$/) {
                $current_attrib = $1;
                $mpid_attrib{$current_mpid}{$current_attrib} = $2;
            } elsif($line=~/^\t(.*)$/) {
                $mpid_attrib{$current_mpid}{$current_attrib} .= $1;
            }
        }
        close $qstat_fh;

            # remove the arrayjob "headers":
        my @array_header_mpids = grep /^\w+\[\]\.\w+$/, keys %mpid_attrib;
        delete @mpid_attrib{@array_header_mpids};       # cutting out a slice

        while(my ($worker_mpid, $attrib) = each %mpid_attrib) {
            my ($job_name, $user, $status_letter) = ($attrib->{'Job_Name'}, $attrib->{'Job_Owner'}, $attrib->{'job_state'});

                # skip the hive jobs that belong to another pipeline:
            next if (($job_name =~ /Hive-/) and (index($job_name, $jnp) != 0));

            $user=~s/\@.*$//;    # trim off the hostname

            my $status = {
                'Q' => 'PEND',
                'R' => 'RUN',
                'E' => 'RUN',   # 'Exiting', some intermediate state between 'R' and 'X/F'
                'X' => 'RUN',   # 'eXiting', an array-element specific state
                'F' => 'DONE',  # 'Finished'
            }->{$status_letter};

            unless($status eq 'DONE') {
                push @status_list, [$worker_mpid, $user, $status];
            }
        }

} else {    # The -w (wide) format is more compact; Meadow Interface v.5 has been adapted to not need more than this:

        my $cmd = "qstat -wta $user_part 2>/dev/null";

#        warn "PBSPro::status_of_all_our_workers() running cmd:\n\t$cmd\n";

        foreach my $line (`$cmd`) {
            if($line=~/^\d+(?:\[\d+\])?\.\w+\s/) {  # only filter out the lines that start with a functional jobid (ignore array_names[])
                my ($worker_pid, $user, $queue, $job_name, $sess_id, $nds, $tsk, $req_mem, $req_time, $status_letter, $elap_time) = split(/\s+/, $line);

                my $status = {
                    'Q' => 'PEND',
                    'R' => 'RUN',
                    'E' => 'RUN',
                    'X' => 'RUN',
                    'F' => 'DONE',  # not one of possible -wta states, but is here for completeness
                }->{$status_letter};
                push @status_list, [$worker_pid, $user, $status];
            }
        }
      } # /parsing --full vs --wide output mode

    }   # /foreach my $meadow_user (@$meadow_users_of_interest)

    return \@status_list;
}


sub check_worker_is_alive_and_mine {
    my ($self, $worker) = @_;

    my $wpid = $worker->process_id();
    $wpid=~s{\[}{\\[}g;
    $wpid=~s{\]}{\\]}g;
    my $this_user = $ENV{'USER'};
    my $cmd = qq{qselect -u $this_user -T -s QREX | grep '$wpid'};

#    warn "PBSPro::check_worker_is_alive_and_mine() running cmd:\n\t$cmd\n";

    my $is_alive_and_mine = qx/$cmd/;
    return $is_alive_and_mine;
}


sub kill_worker {
    my ($self, $worker, $fast) = @_;

    if ($fast) {
        system('qdel', '-Wforce', $worker->process_id());
    } else {
        system('qdel', $worker->process_id());
    }
}


sub submit_workers_return_meadow_pids {
    my ($self, $worker_cmd, $required_worker_count, $iteration, $rc_name, $rc_specific_submission_cmd_args, $submit_log_subdir) = @_;

    my $job_array_common_name               = $self->job_array_common_name($rc_name, $iteration);
    my $index_range                         = ($required_worker_count > 1) ? "1-${required_worker_count}" : '1-2:2';
    my $meadow_specific_submission_cmd_args = $self->config_get('SubmissionOptions');

    my ($submit_stdout_file, $submit_stderr_file);

    if($submit_log_subdir) {
        $submit_stdout_file = $submit_log_subdir.'/log_'.$job_array_common_name;    # the filenames will be autogenerated from PBS_JOBID
        $submit_stderr_file = $submit_log_subdir.'/log_'.$job_array_common_name;    # the filenames will be autogenerated from PBS_JOBID
        mkdir($submit_stdout_file);
        mkdir($submit_stderr_file);
    } else {
        $submit_stdout_file = '/dev/null';
        $submit_stderr_file = '/dev/null';
    }

    my @cmd = ('qsub',
        '-V',   # propagate all ENV variables to the submitted job (off by default)
        '-o' => $submit_stdout_file,
        '-e' => $submit_stderr_file,
        '-N' => $job_array_common_name,
        '-J' => $index_range,
        split_for_bash($rc_specific_submission_cmd_args),
        split_for_bash($meadow_specific_submission_cmd_args),
        '--' => split_for_bash($worker_cmd),
    );

    warn "Executing [ ".$self->signature." ] \t\t".join(' ', @cmd)."\n";

    my ($pbs_jobid, $pbs_array_detected, $pbs_servername);

    open(my $qsub_output_fh, "-|", @cmd) || die "Could not submit job(s): $!, $?";  # let's abort the beekeeper and let the user check the syntax
    while(my $line = <$qsub_output_fh>) {
        if($line=~/^(\d+)(\[\])?\.(\w+)\s*$/) {
            ($pbs_jobid, $pbs_array_detected, $pbs_servername) = ($1, $2, $3);
        } else {
            warn $line;     # assuming it is a temporary blockage that might resolve itself with time
        }
    }
    close $qsub_output_fh;

    if(defined $pbs_jobid) {
        return ($pbs_array_detected ? [ map { $pbs_jobid.'['.$_.'].'.$pbs_servername } (1..$required_worker_count) ] : [ $pbs_jobid.'.'.$pbs_servername ]);
    } else {
        die "Submission unsuccessful\n";
    }
}

1;
