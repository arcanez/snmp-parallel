package SNMP::Parallel::AttributeHelpers::MethodProvider::Result;

=head1 NAME

SNMP::Parallel::AttributeHelpers::MethodProvider::Result - Attribute helper methods

=head1 DESCRIPTION

This module does the role
L<SNMP::Parallel::AttributeHelpers::MethodProvider::Hash>.

=cut

use Moose::Role;
use SNMP::Parallel::Utils qw/match_oid/;
use SNMP::Parallel::Result;

with 'MooseX::AttributeHelpers::MethodProvider::Array';

=head1 METHODS

=head2 push

 $code = $attribute->push($reader, $writer);
 $int = $self->$code([\%args, $ref_oid], [...]);
 $int = $self->$code([\@snmp_result, $ref_oid], [...]);
 $int = $self->$code([$snmp_varbind, $ref_oid], [...]);
 $int = $self->$code([$result_obj, $ref_oid], [...]);

Add a new L<SNMP::Parallel::Result> object to list.

=cut

sub push : method {
    my($attr, $reader, $writer) = @_;

    return sub {
        my $self = shift;

        if(UNIVERSAL::isa($_[0], 'ARRAY')) {
            return unless(ref $_[1]);
            return(push @{ $reader->($self) },
                SNMP::Parallel::Result->new(
                    tag => $_[0]->tag,
                    iid => $_[0]->iid,
                    value => $_[0]->val,
                    type => $_[0]->type,
                    name => $_[0]->name,
                    callback => $SNMP::Parallel::CURRENT_CALLBACK_NAME,
                    _req => $_[1],
                )
            );
        }

        return;
    };
}

=head1 SEE ALSO

L<SNMP::Parallel::AttributeHelpers::Trait::Result>

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Parallel>.

=cut

1;
