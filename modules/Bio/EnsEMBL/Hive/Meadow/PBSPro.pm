=pod 

=head1 NAME

Bio::EnsEMBL::Hive::Meadow::PBSPro

=head1 DESCRIPTION

    This is the 'PBS Pro' implementation of Meadow

=head1 LICENSE

    Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
    Copyright [2016-2023] EMBL-European Bioinformatics Institute

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

use Cwd qw(cwd);
use Time::Piece;
use Time::Seconds;

use Bio::EnsEMBL::Hive::Utils ('split_for_bash');

use base ('Bio::EnsEMBL::Hive::Meadow');


our $VERSION = '5.1';       # Semantic version of the Meadow interface:
                            #   change the Major version whenever an incompatible change is introduced,
                            #   change the Minor version whenever the interface is extended, but compatibility is retained.

=head2 name

   Args        : None
   Description : Determine the PBSPro cluster name, if a PBSPro meadow is available
   Returntype  : String

=cut

sub name {
    my $mcni = 'Server:';
    my @qstat_out = `qstat -B -f 2>/dev/null`;
    foreach my $qstat_line (@qstat_out) {
        if ($qstat_line=~/^$mcni\s+(\S+)/) {
            return $1;
        }
    }

    # On some installations, 'qsub' is not directly runnable on an execution node, so we can double check
    # $PBS_JOBID in case qsub does not provide
    if(($ENV{'PBS_JOBID'}//'')=~/^\d+(?:\[\d+\])?\.(\S+)$/) {
            return $1;
    }

    return undef;
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

    # We only need to list here possible states of jobs and subjobs
    # (jobs within an array) not of arrays themselves
    my $pbs_states = {
        'Q' => 'PEND',  # Queued -- Job is queued, eligible to run or be routed
        'W' => 'PEND',  # Job is waiting for its requested execution time to be reached or job specified a stagein request which failed for some reason.
        'R' => 'RUN',   # Running -- Job is running
        'E' => 'RUN',   # Ending -- Job is exiting after having run
        'X' => 'RUN',   # Expired or deleted -- subjob has completed execution or been deleted
        'F' => 'DONE',  # Finished -- Job is finished. Job has completed execution, job failed during execution, or job was deleted.
        'H' => 'HSUSP', # Job is held. A job is put into a held state by the server or by a user or administrator. A job stays in a held state until it is released by a user or administrator.
        'S' => 'SSUSP', # Suspended -- Job is suspended by server. A job is put into the suspended state when a higher priority job needs the resources.
        'U' => 'USUSP', # Suspended by keyboard activity -- Job is suspended due to workstation becoming busy
        'T' => 'RUN',   # Job is in transition (being moved to a new location)
        'M' => 'RUN',   # Job was moved to another server
    };

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

            if($line=~/^Job Id: (\w+(\[\d*\])?\.\S+)/) {
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
        my @array_header_mpids = grep /^\w+\[\]\.\S+$/, keys %mpid_attrib;
        delete @mpid_attrib{@array_header_mpids};       # cutting out a slice

        while(my ($worker_mpid, $attrib) = each %mpid_attrib) {
            my ($job_name, $user, $status_letter) = ($attrib->{'Job_Name'}, $attrib->{'Job_Owner'}, $attrib->{'job_state'});

                # skip the hive jobs that belong to another pipeline:
            next if (($job_name =~ /Hive-/) and (index($job_name, $jnp) != 0));

            $user=~s/\@.*$//;    # trim off the hostname

            my $status = $pbs_states->{$status_letter};
            unless($status eq 'DONE') {
                push @status_list, [$worker_mpid, $user, $status];
            }
        }

} else {    # The -w (wide) format is more compact; Meadow Interface v.5 has been adapted to not need more than this:

        my $cmd = "qstat -wta $user_part 2>/dev/null";

#        warn "PBSPro::status_of_all_our_workers() running cmd:\n\t$cmd\n";

        foreach my $line (`$cmd`) {
            if($line=~/^\d+(?:\[\d+\])?\.\S+\s/) {  # only filter out the lines that start with a functional jobid (ignore array_names[])
                my ($worker_pid, $user, $queue, $job_name, $sess_id, $nds, $tsk, $req_mem, $req_time, $status_letter, $elap_time) = split(/\s+/, $line);
                my $status = $pbs_states->{$status_letter};
                push @status_list, [$worker_pid, $user, $status];
            }
        }
      } # /parsing --full vs --wide output mode

    }   # /foreach my $meadow_user (@$meadow_users_of_interest)

    return \@status_list;
}

=head2 check_worker_is_alive_and_mine

   Args[1]     : Int $worker. The worker_id of the worker to check
   Example     : if ($meadow->check_worker_is_alive_and_mine($worker_id)) { do_something_with_worker(); }
   Description : Returns 1 if the given worker is alive and running in this meadow
   Returntype  : Boolean

=cut

sub check_worker_is_alive_and_mine {
    my ($self, $worker) = @_;

    my $wpid = $worker->process_id();
    $wpid=~s{\[}{\\[}g;
    $wpid=~s{\]}{\\]}g;
    my $this_user = $ENV{'USER'};
    my $cmd = qq{qselect -u $this_user -T -s QREX};

    my @qselect_out = qx/$cmd/;
    my $is_alive_and_mine = 0;
    foreach my $qselect_line (@qselect_out) {
        if ($qselect_line =~ /$wpid/) {
            $is_alive_and_mine = 1;
        }
    }

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
    my $index_range                         = ($required_worker_count > 1) ? ['-J', "1-${required_worker_count}"] : [];
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
        @$index_range,
        split_for_bash($rc_specific_submission_cmd_args),
        split_for_bash($meadow_specific_submission_cmd_args),
        '--' => split_for_bash($worker_cmd),
        '--cwd' => cwd(),
    );

    warn "Executing [ ".$self->signature." ] \t\t".join(' ', @cmd)."\n";

    my ($pbs_jobid, $pbs_array_detected, $pbs_servername);

    open(my $qsub_output_fh, "-|", @cmd) || die "Could not submit job(s): $!, $?";  # let's abort the beekeeper and let the user check the syntax
    while(my $line = <$qsub_output_fh>) {
        if($line=~/^(\d+)(\[\])?\.(\S+)\s*$/) {
            ($pbs_jobid, $pbs_array_detected, $pbs_servername) = ($1, $2, $3);
        } else {
            warn "Meadow::PBSPro - Submission warning: $line";     # assuming it is a temporary blockage that might resolve itself with time
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
