use inc::Module::Install;

name q(SNMP-Parallel);
all_from q(lib/SNMP/Parallel.pm);

requires q(Fcntl) => 1.0;
requires q(Log::Log4perl) => 1.2;
requires q(Moose) => 0.80;
requires q(MooseX::AttributeHelpers) => 0.20;
requires q(POSIX) => 1.0;
requires q(SNMP) => 5.0;
test_requires q(File::Find) => 1.14;
test_requires q(Log::Log4perl) => 1.26;
test_requires q(Test::More) => 0.94;

bugtracker 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=SNMP-Parallel';
repository 'git://github.com/jhthorsen/snmp-parallel.git';

no_index q(examples);

auto_install;
WriteAll;
