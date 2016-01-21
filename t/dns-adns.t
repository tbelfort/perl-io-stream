# DNS error.
use warnings;
use strict;
use t::share;

if (WIN32) {
    plan skip_all => 'OS unsupported';
}

plan tests => 1;

# cover code which process stale ADNS replies on closed streams
IO::Stream->new({
    host        => "no_such_host_$$.com",
    port        => 80,
    cb          => \&client,
    wait_for    => IN,
})->close();

ok(1);

