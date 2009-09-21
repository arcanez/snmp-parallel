#!perl

use strict;
use warnings;
use lib qw(./lib);
use Log::Log4perl qw(:easy);
use SNMP::Parallel;
use Test::More;

SNMP::initMib();

plan skip_all => 'REAL_RUN is not set' unless($ENV{'REAL_RUN'});
plan tests => 8;

Log::Log4perl->easy_init($ENV{'VERBOSE'} ? $TRACE : $FATAL);

my $parallel = SNMP::Parallel->new(master_timeout => 5);
my @host = qw/localhost/;

ok($parallel, 'object constructed');

$parallel->add(
    dest_host => \@host,
    get => [qw/.1.3.6.1.2.1.1.1.0 sysDescr.0/],
    getnext => '.1.3.6.1.2.1.1.1',
    walk => '.1.3.6.1.2.1.1',
    callback => sub {
        my $host = shift;
        my $error = $host->error;

        is($error, "", "$host retured without error") or return;
        ok(int(@{ $host->results }), "$host returned data");

        for my $obj (@{ $host->results }) {
            #$host->log(trace => "%s> %s=%s", "$host", $obj->name, $obj->value);
        }
    },
);

is($parallel->execute, 1, "execute() completed");

