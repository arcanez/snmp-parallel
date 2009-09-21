package SNMP::Parallel::Callbacks;

=head1 NAME

SNMP::Parallel::Callbacks - SNMP callbacks

=head1 SYNOPSIS

See L<SNMP::Parallel>.

=head1 DESCRIPTION

This package contains default callback methods for L<SNMP::Parallel>.
These methods are called from within an L<SNMP> get/getnext/set/...
method and should handle the response from a SNMP client.

=cut

use strict;
use warnings;
use SNMP::Parallel;
use SNMP::Parallel::Utils qw/:all/;

=head1 CALLBACKS

=head2 set

This method is called after L<SNMP>.pm has completed it's C<set> call
on the C<$host>.

If you want to use SNMP SET, you have to build your own varbind:

 use SNMP::Parallel::Utils qw/varbind/;
 $effective->add( set => varbind($oid, $iid, $value, $type) );

=cut

SNMP::Parallel->add_snmp_callback(set => set => sub {
    my($self, $host, $req, $res) = @_;

    return 'timeout' unless(ref $res);

    for my $i (0..@$res) {
        $host->add_result($res->[$i], $req->[$i]);
    }

    return '';
});

=head2 get

This method is called after L<SNMP>.pm has completed it's C<get> call
on the C<$host>.

=cut

SNMP::Parallel->add_snmp_callback(get => get => sub {
    my($self, $host, $req, $res) = @_;

    return 'timeout' unless(ref $res);

    for my $i (0..@$res) {
        $host->add_result($res->[$i], $req->[$i]);
    }

    return '';
});

=head2 getnext

This method is called after L<SNMP>.pm has completed it's C<getnext> call
on the C<$host>.

=cut

SNMP::Parallel->add_snmp_callback(getnext => getnext => sub {
    my($self, $host, $req, $res) = @_;

    return 'timeout' unless(ref $res);

    for my $i (0..@$res) {
        $host->add_result($res->[$i], $req->[$i]);
    }

    return '';
});

=head2 walk

This method is called after L<SNMP>.pm has completed it's C<getnext> call
on the C<$host>. It will continue sending C<getnext> requests, until an
OID branch is walked.

=cut

SNMP::Parallel->add_snmp_callback(walk => getnext => sub {
    my($self, $host, $req, $res) = @_;
    my $i = 0;
    my $splice;

    return 'timeout' unless(ref $res);

    while($i < @$res) {
        $splice = 1;

        my $res_i = $res->[$i] or next;
        my $req_i = $req->[$i];
        my($res_oid, $req_oid) = make_numeric_oid($res_i->name, $req_i->name);

        if(match_oid($res_oid, $req_oid)) {
            $host->add_result($res_i, $req_i);
            $req_i->[0] = $res_oid;
            $splice = 0;
        }
    }
    continue {
        if($splice) {
            splice @$req, $i, 1;
            splice @$res, $i, 1;
        }
        else {
            $i++;
        }
    }

    if(@$res) {
        $$host->getnext($req, [ '&callback_walk' => $self, $host, $req ]);
        return;
    }
    else {
        return '';
    }
});

=head1 DEBUGGING

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Parallel>.

=cut

1;
