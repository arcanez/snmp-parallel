#!perl

use strict;
use warnings;
use lib qw(./lib);
use Test::More tests => 13;

BEGIN {
    use_ok('SNMP::Parallel::Host');
}

my $addr = "127.0.0.1";
my $host = SNMP::Parallel::Host->new(
               address => $addr,
               callback => sub { 42 },
           );
my $result = SNMP::Varbind->new(["sysDescr", 1, 42, 'INTEGER']);
my $tmp;

is_deeply($host->arg, {
    Version   => '2c',
    Community => 'public',
    Timeout   => 1e6,
    Retries   => 2
}, "args ok");

is($host->address, $addr, "object is constructed");
is("$host", $addr, "address overload");
is(int(@$host), 0, "varbind overloaded");
is($host->(), 42, "callback overloaded");
isa_ok($$host, "SNMP::Session", "session");

{
    local $SNMP::Parallel::CURRENT_CALLBACK_NAME = 'get';
    ok($host->add_result($result, $result), 'result added');
    is(int( @{ $host->results } ), 1, 'result defined');
}

$tmp = $host->results->[0];

is("$tmp", $result->val, "res->value overload");
is($tmp->name, $result->name, "res->oid");
is($tmp->type, $result->type, "res->type");
is($tmp->callback, 'get', 'res->callback');
