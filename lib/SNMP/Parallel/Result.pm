package SNMP::Parallel::Result;

=head1 NAME

SNMP::Paralell::Result - Object for SNMP results

=cut

use Moose;
use overload (
    q{""} => sub { shift->value },
    fallback => 1,
);

=head1 ATTRIBUTES

=head2 value

 $value = $self->value;

The value retrieved using SNMP. Can be types listed under L<type>.

=cut

has value => (
    is => 'ro',
    isa => 'Any',
    required => 1,
);

=head2 type

 $str = $self->type;

Returns the SNMP type retrieved:

OBJECTID, OCTETSTR, INTEGER, NETADDR, IPADDR, COUNTER, COUNTER64, GAUGE,
UINTEGER, TICKS, OPAQUE, NULL.

=cut

has type => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

=head2 oid

 $str = $self->oid;

=cut

has oid => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

=head2 iid

 $str = $self->iid;

=cut

has iid => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

=head1 AUTHOR

See L<SNMP::Paralell>.

=cut

1;
