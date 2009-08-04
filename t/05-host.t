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
my $result = {
                 value => 123,
                 type => 'INTEGER',
                 oid => '1.2.3.4',
                 iid => '1',
             };
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

ok($host->add_result($result), "result added");
ok($host->results->{$result->{'oid'}}, "results->oid");
ok($host->results->{$result->{'oid'}}->{$result->{'iid'}}, "results->oid->iid");
$tmp = $host->results->{$result->{'oid'}}->{$result->{'iid'}};

is("$tmp", $result->{'value'}, "res->value overload");
is($tmp->oid, $result->{'oid'}, "res->oid");
is($tmp->type, $result->{'type'}, "res->type");
