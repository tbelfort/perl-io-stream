# Write timeout.
use warnings;
use strict;
use IO::Stream::const ();
BEGIN {
    local $SIG{__WARN__} = sub {};  # no 'constant redefined' warning
    *IO::Stream::const::TOWRITE     = sub () { 0.5 };
}
use t::share;


@CheckPoint = (
    [ 'client',     RESOLVED, undef        ], 'client: RESOLVED',
    [ 'client',     CONNECTED|OUT, undef   ], 'client: CONNECTED',
    {
	small_first_pkt => [
	    [ 'server',     8192,                  ], 'server: read 8192 bytes',
	],
	usual_first_pkt => [
	    [ 'server',     16384,                 ], 'server: read 16384 bytes',
	],
    },
    [ 'server',     16384,                 ], 'server: read 16384 bytes',
    [ 'server',     16384,                 ], 'server: read 16384 bytes',
    [ 'server',     16384,                 ], 'server: read 16384 bytes',
    [ 'server',     16384,                 ], 'server: read 16384 bytes',
    [ 'server',     16384,                 ], 'server: read 16384 bytes',
    [ 'server',     16384,                 ], 'server: read 16384 bytes',
    [ 'server',     16384,                 ], 'server: read 16384 bytes',
    [ 'server',     16384,                 ], 'server: read 16384 bytes',
    [ 'server',     16384,                 ], 'server: read 16384 bytes',
);
plan tests => checkpoint_count();



my $srv_sock = tcp_server('127.0.0.1', 4444);
my %srv_t;
my $srv_w = EV::io($srv_sock, EV::READ, sub {
    accept my $sock, $srv_sock or die "accept: $!";
    nonblocking($sock);
    my $i = 10;
    $srv_t{$sock} = EV::timer 0, 0.1, sub { server($sock, \$i) };
});

IO::Stream->new({
    host        => '127.0.0.1',
    port        => 4444,
    cb          => \&client,
    wait_for    => RESOLVED|CONNECTED|OUT|SENT,
    out_buf     => ('x' x 2048000),
});

EV::loop;


sub server {
    my ($sock, $i) = @_;
    my $n = sysread $sock, my $buf, 16384;
    checkpoint($n);
    EV::unloop if !--$$i;
    return;
}


sub client {
    my ($io, $e, $err) = @_;
    if ($e == OUT) {
        $io->{out_buf} .= 'x' x (2048000 - length $io->{out_buf});
    } else {
        checkpoint($e, $err);
    }
    EV::unloop if $err;
}

