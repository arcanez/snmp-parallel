#!perl

use strict;
use warnings;
use lib qw(./lib);
use Test::More tests => 4;

BEGIN {
    use_ok( 'SNMP::Parallel::Utils' );
}

is(SNMP::Parallel::Utils::match_oid("1.3.6.10", "1.3.6"), 10, "oid match");
is(SNMP::Parallel::Utils::make_name_oid("1.3.6.1.2.1.1.1"), "sysDescr", "name match numeric");
is(SNMP::Parallel::Utils::make_numeric_oid("sysDescr"), ".1.3.6.1.2.1.1.1", "numeric match numeric");

