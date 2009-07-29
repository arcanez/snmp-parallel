#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SNMP::Parallel' );
}

diag( "Testing SNMP::Parallel $SNMP::Parallel::VERSION, Perl $], $^X" );
