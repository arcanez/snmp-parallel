package SNMP::Parallel::Host;

=head1 NAME

SNMP::Parallel::Host - SNMP::Parallel host class

=head1 DESCRIPTION

This is a helper module for SNMP::Parallel. It does the role
L<SNMP::Parallel::Role>.

=cut

use Moose;
use SNMP;
use SNMP::Parallel::Result;
use POSIX qw/:errno_h/;
use overload (
    q("")  => sub { shift->address },
    q(&{}) => sub { shift->callback },
    q(@{}) => sub { shift->_varlist },
    q(${}) => sub { \shift->session },
    fallback => 1,
);

with 'SNMP::Parallel::Role';

=head1 OBJECT ATTRIBUTES

=head2 address

 $address = $self->address;
 $address = "$self";

Returns host address.

=cut

has address => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

=head2 sesssion

 $snmp_session = $self->session;
 $snmp_session = $$self;
 $bool => $self->has_session;
 $self->clear_session;

Returns a L<SNMP::Session> or undef on failure.

=cut

has session => (
    is => 'ro',
    isa => 'Maybe[SNMP::Session]',
    lazy_build => 1,
);

sub _build_session {
    my $self = shift;
    local $! = 0;

    if(my $session = SNMP::Session->new(%{ $self->arg })) {
        $self->fatal("");
        return $session;
    }
    else {
        my($retry, $msg) = _check_errno();
        $self->fatal($msg);
        return;
    }
}

=head2 results

 $hash_ref = $self->results;
 $self->clear_results;
 $self->add_result(...);

Get the retrieved SNMP results:

 {
   $oid => {
     $iid => $result_object,
     ...,
   },
   ...,
 }

See L<SNMP::Parallel::Result>. for the api for the stored object.
See L<SNMP::Parallel::AttributeHelpers::MethodProvider::Result> for the
different ways to use C<add_result(...)>.

=cut

has results => (
    traits => [qw/SNMP::Parallel::AttributeHelpers::Trait::Result/],
    clearer => 'clear_results',
    provides => {
        set => 'add_result',
    },
);

=head2 fatal

 $str = $self->fatal;

Returns a string if the host should stop retrying an action. Example:

 until($session = $self->session) {
    die $self->fatal if($self->fatal);
 }

=cut

has fatal => (
    is => 'rw',
    isa => 'Str',
    default => "",
);

=head1 METHODS

=head2 BUILD

 $self->BUILD({ varlist => [...], ... });

Called after C<new()>. See L<Moose::Object>.

Sets up varlist.

=cut

sub BUILD {
    my $self = shift;
    my $args = shift;

    if(my $varlist = $args->{'varlist'}) {
        $self->add_varlist(@$varlist);
    }
}

# ($retry, $reason) = _check_errno;
sub _check_errno {
    my $err    = $!;
    my $string = "$!";
    my $retry  = 0;

    if($err) {
        if(
            $err == EINTR  ||  # Interrupted system call
            $err == EAGAIN ||  # Resource temp. unavailable
            $err == ENOMEM ||  # No memory (temporary)
            $err == ENFILE ||  # Out of file descriptors
            $err == EMFILE     # Too many open fd's
        ) {
            $string .= ' (will retry)';
            $retry   = 1;
        }
    }
    else {
        $string  = "Couldn't resolve hostname";  # guesswork
    }

    return $retry, $string;
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Parallel>.

=cut

1;
