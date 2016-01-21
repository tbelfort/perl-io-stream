# DNS error.
use warnings;
use strict;
use t::share;

if (WIN32) {
    plan skip_all => 'OS unsupported';
}

plan tests => 1;

IO::Stream->new({
    host        => 'no.such.host',
    port        => 80,
    cb          => \&client,
    wait_for    => IN,
});

EV::loop;

sub client {
    my ($io, $e, $err) = @_;
    # sometimes test fail because we got 'Connection reset by peer' instead
    is($err, IO::Stream::EDNSNXDOMAIN, 'no such host');
    EV::unloop;
}

