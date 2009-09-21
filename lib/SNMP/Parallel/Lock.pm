package SNMP::Parallel::Lock;

=head1 NAME

SNMP::Parallel::Lock - A role for locking

=head1 SYNOPSIS

 while(@tasks) {
   $self->wait_for_lock;
   # do stuff
   $self->unlock;
 }

=cut

use Moose::Role;
use Fcntl ':flock';

=head1 METHODS

=head2 wait_for_lock

 $bool = $self->wait_for_lock;

Returns true when the lock has been released. Check C<$!> on failure.

=cut

sub wait_for_lock {
    my $self = shift;

    $self->log(trace => "Waiting for lock");

    unless(flock DATA, LOCK_EX) {
        $self->log(fatal => "Locking failed: %s", $!);
        return;
    }

    return 1;
}

=head2 unlock

 $bool = $self->unlock;

Will unlock the lock and return true. Check C<$!> on failure.

=cut

sub unlock {
    my $self = shift;

    $self->log->trace("Unlocking lock");

    unless(flock DATA, LOCK_EX) {
        $self->log(fatal => "Unlocking failed: %s", $!);
        return;
    }

    return 1;
}

=head1 ACKNOWLEDGEMENTS

Sigurd Weisteen Larsen contributed with a better locking mechanism.

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Parallel>

=cut

1;

__DATA__
This is the content of the locked filehandle :-)
