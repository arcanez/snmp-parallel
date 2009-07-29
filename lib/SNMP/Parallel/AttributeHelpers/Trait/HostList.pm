package SNMP::Parallel::AttributeHelpers::Trait::HostList;

=head1 NAME

SNMP::Parallel::AttributeHelpers::Trait::HostList

=cut

use Moose::Role;
use SNMP::Parallel::Host;
use Moose::Util::TypeConstraints;
use MooseX::AttributeHelpers;
use SNMP::Parallel::AttributeHelpers::MethodProvider::HostList;

with 'MooseX::AttributeHelpers::Trait::Collection::Hash';

=head1 ATTRIBUTES

=head2 method_provider

 $str = $self->method_provider;

=cut

has method_provider => (
    is => 'ro',
    isa => 'ClassName',
    predicate => 'has_method_provider',
    default => 'SNMP::Parallel::AttributeHelpers::MethodProvider::HostList',
);

=head1 METHODS

=head2 _process_options

Set default options unless specified:

 {
   is => 'ro',
   isa => 'HashRef[SNMP::Parallel::Host]',
   default => sub { [] },
 }

=cut

before _process_options => sub {
    my($class, $name, $options) = @_;

    $options->{'is'}      ||= 'ro';
    $options->{'isa'}     ||= 'HashRef[SNMP::Parallel::Host]';
    $options->{'default'} ||= sub { {} };
};

=head1 SEE ALSO

L<SNMP::Parallel::AttributeHelpers::MethodProvider::VarList>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Parallel>.

=cut

1;
