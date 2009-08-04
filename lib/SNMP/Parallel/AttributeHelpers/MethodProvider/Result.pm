package SNMP::Parallel::AttributeHelpers::MethodProvider::Result;

=head1 NAME

SNMP::Parallel::AttributeHelpers::MethodProvider::Result

=head1 DESCRIPTION

This module does the role
L<SNMP::Parallel::AttributeHelpers::MethodProvider::Hash>.

=cut

use Moose::Role;
use SNMP::Parallel qw/match_oid/;
use SNMP::Parallel::Result;

with 'MooseX::AttributeHelpers::MethodProvider::Hash';

=head1 METHODS

=head2 set

 $code = $attribute->set($reader, $writer);
 $result_obj = $self->$code(\%args);
 $result_obj = $self->$code(\@snmp_result, $ref_oid);
 $result_obj = $self->$code($result_obj);

Add a new L<SNMP::Parallel::Result> object to list.

=cut

sub set : method {
    my($attr, $reader, $writer) = @_;
    my $super = MooseX::AttributeHelpers::MethodProvider::Hash::set(@_);

    return sub {
        my $self = shift;

        if(ref $_[0] eq 'ARRAY') {
            my $r   = $_[0];
            my $ref = $_[1] || q(.);
            my $iid = $r->[1] || match_oid($r->[0], $ref) || 1;

            return $super->($self, $_[0] => {
                $iid => SNMP::Parallel::Result->new({
                    value => $r->[2],
                    type => $->[3],
                    oid => $r->[0],
                    iid => $iid,
                }),
            });
        }
        elsif(ref $_[0] eq 'HASH') {
            my $oid = $_[0]->{'oid'};
            my $iid = $_[0]->{'iid'};
            return $super->($self,
                $oid => { $iid => SNMP::Parallel::Result->new($_[0]) }
            );
        }
        elsif(blessed $_[0])  {
            return $super->($self, $_[0]->oid => { $_[0]->iid => $_[0] });
        }
        else {
            confess "Unknown input: @_";
        }
    };
}

=head1 SEE ALSO

L<SNMP::Parallel::AttributeHelpers::Trait::VarList>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Parallel>.

=cut

1;
