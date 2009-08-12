#!perl

use strict;
use warnings;
use lib qw(./lib);
use Log::Log4perl qw(:easy);
use Test::More tests => 8;

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
        $obj->$method($host, $req, $res);
        return;
    };
    *SNMP::Session::getnext = sub {
        return unless @_;
        my($method, $obj, $host, $req) = @{ $_[2] };
        my $res = ["foo"];
        ok($obj->can($method), "$host / SNMP::Parallel can $method()");
        $obj->$method($host, $req, $res);
        return;
    };
}

Log::Log4perl->easy_init($ENV{'VERBOSE'} ? $TRACE : $FATAL);

my $parallel = SNMP::Parallel->new;
my @host = qw/10.1.1.2/;
my @oid = qw/sysDescr/;
my @errors = ('timeout', '');

ok($parallel, 'object constructed');

$parallel->add(
    dest_host => \@host,
    get => \@oid,
    getnext => \@oid,
    callback => sub {
        my($host, $error) = @_;
        is($error, shift(@errors), "error is ok from client");

        if($host->results) {
            is_deeply($host->results, {}, "results ok");
        }
    },
);

is($parallel->_dispatch, 0, "dispatcher run");

