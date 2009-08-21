package SNMP::Parallel::Meta::Role;

=head1 NAME

SNMP::Parallel::Meta::Role - Meta information for SNMP::Efffective

=head1 DESCRIPTION

Adds extra information about callback methods.

=cut

use Moose::Role;

=head1 ATTRIBUTES

=head2 snmp_callback_map

 $hash_ref = $meta->snmp_callback_map;

 {
   $add_keyword => $snmp_method,
   ...,
 }

=cut

has snmp_callback_map => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
);

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Parallel>.

=cut

1;
