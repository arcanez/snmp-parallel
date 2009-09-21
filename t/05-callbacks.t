#!perl

use strict;
use warnings;
use lib qw(./lib);
use SNMP::Parallel::Callbacks;
use Test::More tests => 1;

my $parallel = SNMP::Parallel->new;
my $methods = $parallel->meta->snmp_callback_map;

can_ok($parallel, map { "&callback_$_" } keys %$methods);

