package SNMP::Parallel;

=head1 NAME

SNMP::Parallel - An effective SNMP-information-gathering module

=head1 VERSION

0.00_0001

=head1 DISCLAIMER

THIS MODULE HAS NOT BEEN TESTED EXTENSIVELY!

Please post any feedback and bug reports to
C<bug-snmp-parallel at rt.cpan.org>.

=head1 SYNOPSIS

 use SNMP::Parallel;
 
 my $snmp = SNMP::Parallel->new(
     max_sessions   => $NUM_POLLERS,
     master_timeout => $TIMEOUT_SECONDS,
 );

 $snmp->add(
     dest_host => $ip,
     callback  => sub { store_data() },
     get       => [ '1.3.6.1.2.1.1.3.0', 'sysDescr' ],
 );

 # lather, rinse, repeat
 # retrieve data from all hosts

 $snmp->execute;

=head1 DESCRIPTION

This module collects information, over SNMP, from many hosts and many OIDs,
really fast.

It is a wrapper around the facilities of C<SNMP.pm>, which is the Perl
interface to the C libraries in the C<SNMP> package. Advantages of using
this module include:

=over 4

=item Simple configuration

The data structures required by C<SNMP> are complex to set up before
polling, and parse for results afterwards. This module provides a simpler
interface to that configuration by accepting just a list of SNMP OIDs or leaf
names.

=item Parallel execution

Many users are not aware that C<SNMP> can poll devices asynchronously
using a callback system. By specifying your callback routine as in the
L</"SYNOPSIS"> section above, many network devices can be polled in parallel,
making operations far quicker. Note that this does not use threads.

=item It's fast

To give one example, C<SNMP::Parallel> can walk, say, eight indexed OIDs
(port status, errors, traffic, etc) for around 300 devices (that's 8500 ports)
in under 30 seconds. Storage of that data might take an additional 10 seconds
(depending on whether it's to RAM or disk). This makes polling/monitoring your
network every five minutes (or less) no problem at all.

=back

The interface to this module is simple, with few options. The sections below
detail everything you need to know.

=head1 METHODS ARGUMENTS

The method arguments are very flexible. Any of the below acts as the same:

 $obj->method(MyKey   => $value);
 $obj->method(my_key  => $value);
 $obj->method(My_Key  => $value);
 $obj->method(mYK__EY => $value);

=head1 SEE ALSO

This module does L<SNMP::Parallel::Role> and L<SNMP::Parallel::Lock>.

It is a fork of L<SNMP::Effective>. This is built on L<Moose> and has a
slightly better interface. Unfortunatly it's not 100% compatible with
L<SNMP::Effective> so it had to get a new name.

=cut

use Moose -traits => 'SNMP::Parallel::Meta::Role';
use SNMP;

with qw/SNMP::Parallel::Role SNMP::Parallel::Lock/;

# load default callbacks
require SNMP::Parallel::Callbacks;

our $VERSION = '0.00_001';
our $CURRENT_CALLBACK_NAME; # used in AttributeHelpers::MethodProvider::Result


=head1 OBJECT ATTRIBUTES

=head2 master_timeout

 $seconds = $self->master_timeout;

Maximum seconds for L<execute()> to run. Default is undef, which means forever.

=cut

has master_timeout => (
    is => 'ro',
    isa => 'Maybe[Int]',
);

=head2 max_sessions

 $int = $self->max_sessions;

How many concurrent hosts to retrieve data from.

=cut

has max_sessions => (
    is => 'ro',
    isa => 'Int',
    default => 1,
);

=head2 sessions

 $int = $self->sessions;

Returns the number of active sessions.

=cut

has sessions => (
    traits => [qw/MooseX::AttributeHelpers::Trait::Counter/],
    is => 'rw',
    isa => 'Int',
    default => 0,
    provides => {
        inc => '_inc_sessions',
        dec => '_dec_sessions',
        reset => '_reset_session_counter',
    },
);

has _hostlist => (
    traits => [qw/SNMP::Parallel::AttributeHelpers::Trait::HostList/],
    provides => {
        set => '_add_host',
        get => 'get_host',
        delete => 'delete_host',
        shift => '_shift_host',
        keys => 'hosts',
    },
);

=head1 METHODS

=head2 BUILDARGS

 $hash_ref = $self->BUILDARGS(%args);
 $hash_ref = $self->BUILDARGS({ foo => bar });

See L<METHODS ARGUMENTS>.

=cut

sub BUILDARGS {
    my $class = shift;
    my $args  = @_ % 2 ? $_[0] : {@_};

    my %translate = qw/
        mastertimeout master_timeout
        maxsessions   max_sessions
        desthost      dest_host
    /;

    for my $k (keys %$args) {
        my $v =  delete $args->{$k};
           $k =  lc $k;
           $k =~ s/_//gmx;
           $k =  $translate{$k} if($translate{$k});
        $args->{$k} = $v;
    }

    return $args;
}

=head2 add

 $self->add(%arguments);

Adding information about what SNMP data to get and where to get it.

=head3 Arguments

=over 4

=item C<dest_host>

Either a single host, or an array-ref that holds a list of hosts. The format
is whatever C<SNMP> can handle.

=item C<arg>

A hash-ref of options, passed on to SNMP::Session.

=item C<callback>

A reference to a sub which is called after each time a request is finished.

=item C<heap>

This can hold anything you want. By default it's an empty hash-ref.

=item C<get> / C<getnext> / C<walk>

Either "oid object", "numeric oid", SNMP::Varbind SNMP::VarList or an
array-ref containing any combination of the above.

=item C<set>

Either a single SNMP::Varbind or a SNMP::VarList or an array-ref of any of
the above.

=back

This can be called with many different combinations, such as:

=over 4

=item C<dest_host> / any other argument

This will make changes per dest_host specified. You can use this to change arg,
callback or add OIDs on a per-host basis.

=item C<get> / C<getnext> / C<walk> / C<set>

The OID list submitted to C<add()> will be added to all dest_host, if no
dest_host is specified.

=item C<arg> / C<callback>

This can be used to alter all hosts' SNMP arguments or callback method.

=back

=cut

sub add {
    my $self = shift;
    my $in   = $self->BUILDARGS(@_) or return;

    # don't mangle input
    local $in->{'dest_host'} = $in->{'dest_host'};
    local $in->{'varlist'}; 

    # setup host
    if($in->{'dest_host'}) {
        unless(ref $in->{'dest_host'} eq 'ARRAY') {
            $in->{'dest_host'} = [$in->{'dest_host'}];
        }
    }

    # setup varlist
    for my $k (keys %{ $self->meta->callback_map }) {
        next unless($in->{$k});
        push @{ $in->{'varlist'} }, [
            $k => ref $in->{$k} eq 'ARRAY' ? @{$in->{$k}} : $in->{$k}
        ];
    }

    # add/modify hosts
    if(ref $in->{'dest_host'} eq 'ARRAY') {
        $in->{'varlist'} ||= $self->_varlist;

        for my $addr (@{$in->{'dest_host'}}) {

            # remove from debug output
            local $in->{'dest_host'};
            delete $in->{'dest_host'};

            if(my $host = $self->get_host($addr)) {
                $self->log(debug => 'Update "%s": %s', $addr, $in);
                $host->add_varlist(@{ $in->{'varlist'} });
                $self->_add_host({ # replace existing host
                    address  => $addr,
                    arg      => $in->{'arg'}      || $host->arg,
                    heap     => $in->{'heap'}     || $host->heap,
                    callback => $in->{'callback'} || $host->callback,
                    varlist  => $host->_varlist,
                });
            }
            else {
                $self->log(debug => 'Add "%s": %s', $addr, $in);
                $self->_add_host({
                    address  => $addr,
                    arg      => $in->{'arg'}      || $self->arg,
                    heap     => $in->{'heap'}     || $self->heap,
                    callback => $in->{'callback'} || $self->callback,
                    varlist  => $in->{'varlist'}  || $self->_varlist,
                });
            }
        }
    }

    # add/update main object
    else {
        $self->log(debug => 'Update main object: %s', $in);
        $self->add_varlist(@{$in->{'varlist'}}) if($in->{'varlist'});
        $self->arg($in->{'arg'})                if($in->{'arg'});
        $self->callback($in->{'callback'})      if($in->{'callback'});
        $self->heap($in->{'heap'})              if(defined $in->{'heap'});
    }

    return 1;
}

=head2 execute

 $bool = $self->execute;

This method starts setting and/or getting data. It will run as long as
necessary, or until L<master_timeout> seconds has passed. Every time some
data is set and/or retrieved, it will call the callback-method, as defined
globally or per host.

Return true on success, and false if L</master_timeout> is reached before
all data is collected.

=cut

sub execute {
    my $self    = shift;
    my $timeout = $self->master_timeout;

    # no hosts to get data from
    unless($self->hosts) {
        $self->log(warn => 'Cannot execute: No hosts defined');
        return 1;
    }

    $self->log(warn => 'Execute dispatcher with timeout=%s', $timeout);

    if($self->_dispatch) {
        if($timeout) {
            eval {
                SNMP::MainLoop($timeout, sub { die "timeout\n" });
                1;
            } or do {
                $self->log(fatal => 'execute() failed: %s', $@);
                return 0;
            };
        }
        else {
            SNMP::MainLoop();
        }
    }

    $self->log(warn => 'Done running the dispatcher');

    return 1;
}

# called from execute()
sub _dispatch {
    my $self = shift;
    my $host = shift;
    my($request, $req_id, $new, $snmp_method, $callback);

    $self->wait_for_lock;

    if($host and @$host == 0) {
        $self->log(info => '%s complete', "$host");
        $self->_dec_sessions;
    }

    HOST:
    while($self->sessions < $self->max_sessions or $host) {
        $host      ||= $self->_shift_host   or last HOST;
        $request     = $host->shift_varbind or next HOST;
        $snmp_method = $self->meta->snmp_callback_map->{$request->[0]};
        $callback    = $self->meta->callback_map->{$request->[0]};
        $req_id      = undef;
        $new         = 0;

        unless($host->has_session) {
            $new = 1;
        }
        unless($host->session) {
            # $host->error is set inside session()
            $host->($host);
            next HOST;
        }

        # ready request
        if($$host->can($snmp_method)) {
            $req_id = $$host->$snmp_method(
                          $request->[1],
                          [ $callback, $self, $host, $request->[1] ]
                      );

            $self->log(trace => '%s->%s(%s, [%s, $self, %s, %s])',
                "$host", $snmp_method, "$request->[1]",
                $callback, "$host", "$request->[1]",
            );

            unless($req_id) {
                $host->error($host->_snmp_errstr || 'Invalid request');
                $host->($host);
            }
        }

        $host->error("");
    }
    continue {
        if($new and $req_id) {
            $self->_inc_sessions;
        }
        $host = undef;
    }

    $self->log(debug => 'Sessions/max-sessions: %i<%i',
        $self->sessions, $self->max_sessions
    );

    unless($self->hosts or $self->sessions) {
        $self->log(info => 'SNMP::finish() is next up');
        SNMP::finish();
    }

    $self->unlock;

    return $self->hosts || $self->sessions;
}

=head2 add_snmp_callback

 $class->add_snmp_callback($name, $snmp_method, sub {});
 $self->add_snmp_callback($name, $snmp_method, sub {});

Will add a callback for L<SNMP::Parallel>.

C<$name> is what you refere to in L<SNMP::Parallel::add()>:

 $self->add( $name => ['sysDescr'] );

C<$snmp_method> is the method which should be called on the
L<SNMP::Session> object.

See L<SNMP::Parallel::Callbacks> for default callbacks.

=cut

sub add_snmp_callback {
    my($self, $name, $snmp_method, $sub) = @_;

    unless(SNMP::Session->can($snmp_method)) {
        confess "SNMP::Session cannot '$snmp_method'";
    }

    my $meta = $self->meta;
    my $callback_name = "\x26callback_$name";
    my $around_cb_sub = sub {
        local $CURRENT_CALLBACK_NAME = $name;

        my $next  = shift;
        my $self  = shift;
        my $host  = $_[0];
        my $error = $self->$next(@_);

        # special case to enable a callback to call itself
        # see SNMP::Parallel::Callbacks::walk() for example
        # this means that q() = no error
        unless(defined $error) {
            return;
        }

        $self->log(debug => 'Callback for %s...', "$host");
        $host->error($error);
        $host->($host);
        $host->clear_results;

        return $self->_dispatch($host);
    };

    $meta->snmp_callback_map->{$name} = $snmp_method;
    $meta->callback_map->{$name} = $callback_name;
    $meta->add_method($callback_name => $sub);
    $meta->add_around_method_modifier($callback_name => $around_cb_sub);
}

=head2 get_host

 $host_obj = $self->get_host($hostname);

=head2 delete_host

 $host_obj = $self->delete_host($hostname);

=head2 hosts

 @hostnames = $self->hosts;

=head1 The callback method

When C<SNMP> is done collecting data from a host, it calls a callback
method, provided by the C<< Callback => sub{} >> argument. Here is an
example of a callback method:

 sub my_callback {
   my $host = shift;

   if(my $error = $host->error) {
      warn "$host failed with this error: $error";
      return;
   }

   printf '%s returned data:\n', $host;

   for my $obj (@{ $host->results }) {
     printf "%s => %s", $obj->name, "$obj";
   }
 }

=head1 DEBUGGING

Debugging is enabled through Log::Log4perl. If nothing else is spesified,
it will default to "error" level, and print to STDERR. The component-name
you want to change is "SNMP::Parallel", inless this module ins inherited.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-snmp-parallel at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SNMP-Parallel>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Various contributions by Oliver Gorwits.

Sigurd Weisteen Larsen contributed with a better locking mechanism.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jan Henning Thorsen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Jan Henning Thorsen, C<< <jhthorse at cpan.org> >>

=cut

1;
