#!perl

use strict;
use warnings;
use lib qw(./lib);
use Log::Log4perl qw(:easy);
use Test::More tests => 13;

my @callbacks;

BEGIN {
    use_ok( 'SNMP::Parallel' );

    # mock SNMP::Session methods
    no warnings 'redefine';
    *SNMP::Session::new = sub {
        return bless {}, "SNMP::Session"
    };
    *SNMP::Session::get = sub {
        my($method, $obj, $host, $req) = @{ $_[2] };
        my $res = undef;
        ok($obj->can($method), "$host / SNMP::Parallel can $method()");
        push @callbacks, [$obj, $method, $host, $req, $res];
        return;
    };
    *SNMP::Session::getnext = sub {
        return unless @_;
        my($method, $obj, $host, $req) = @{ $_[2] };
        my $res = ["foo"];
        ok($obj->can($method), "$host / SNMP::Parallel can $method()");
        push @callbacks, [$obj, $method, $host, $req, $res];
        return;
    };
}

Log::Log4perl->easy_init($ENV{'VERBOSE'} ? $TRACE : $FATAL);

my $parallel = SNMP::Parallel->new;
my @host = qw/10.1.1.2/;
my @oid = qw/foo sysDescr.1/;
my @errors = ('Invalid request', 'timeout', 'Invalid request', '');

ok($parallel, 'object constructed');

$parallel->add(
    dest_host => \@host,
    get => \@oid,
    getnext => \@oid,
    callback => sub {
        my $host = shift;
        is($host->error, shift(@errors), "host->error");
        is_deeply($host->results, [], "host->results");
    },
);

is($parallel->_dispatch, 0, "->_dispatch");

for(@callbacks) {
    my $obj = shift @$_;
    my $method = shift @$_;
    $obj->$method(@$_);
}

