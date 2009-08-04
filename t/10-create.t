#!perl

use strict;
use warnings;
use lib qw(./lib);
use Log::Log4perl qw(:easy);
use Test::More tests => 20;

BEGIN {
    use_ok( 'SNMP::Parallel' );
    no warnings 'redefine';
    *SNMP::Session::get = sub {
        my($method, $obj, $host) = @{ $_[2] };
        ok($obj->can($method), "$host / SNMP::Parallel can $method()");
    };
}

my $max_sessions = 2;
my @host = qw/10.1.1.2/;
my @walk = qw/sysDescr/;
my $timeout = 3;
my($parallel, $host, $req);

Log::Log4perl->easy_init($ENV{'VERBOSE'} ? $TRACE : $FATAL);

$parallel = SNMP::Parallel->new(max_sessions => $max_sessions);

ok($parallel, 'object constructed');
ok(!$parallel->execute, "cannot execute without hosts");

# add
$parallel->add(
    Dest_Host => \@host,
    Arg      => { Timeout => $timeout },
    CallbaCK => sub { return "test" },
    walK     => \@walk,
);

is(scalar($parallel->hosts), scalar(@host), 'add two hosts');

ok($host = $parallel->_shift_host, "host fetched");
ok($req = shift @$host, "request defined");
is($req->[0], "walk", "method is ok");
isa_ok($req->[1], "SNMP::VarList", "VarList");

# add with defaults
$parallel->add(get => 'sysName', heap => { foo => 42 });
$parallel->add(getnext => 'ifIndex');
$parallel->add(dest_host => '127.0.0.1');

ok($host = $parallel->_shift_host, "host with defauls fetched");
ok($req = shift @$host, "first default request defined");
is($req->[0], "get", "first default method is ok");
ok($req = shift @$host, "second default request defined");
is($req->[0], "getnext", "second default method is ok");
is_deeply($host->heap, { foo => 42 }, "default heap is set");

# dispatcher
push @host, '10.1.1.3';
$parallel->add(dest_host => \@host);
ok($parallel->_dispatch, "dispatcher set up hosts");
is($parallel->sessions, $max_sessions, "correct number of sessions");


{
    no warnings 'redefine';
    *SNMP::Session::new = sub { undef };
    $host->clear_session;
    ok(!$host->session, "session is undef");
    like($host->fatal, qr{resolve hostname}, "session guesswork error is ok");
}
