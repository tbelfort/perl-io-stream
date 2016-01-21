# Use case: echo client/server
use warnings;
use strict;
use t::share;

my $banner  = "Server ready";
my $msg     = "Test message!\0\n";

use constant ACCEPTED => 123;
@CheckPoint = (
    [ '__ANON__',   ACCEPTED        ], 'accept incoming connection',
    [ 'client',     IN              ], 'client: got server banner',
    [ 'client',     $banner         ], 'client: banner is correct',
    [ 'client',     SENT            ], 'client: request sent',
    [ 'server',     EOF             ], 'server: got eof',
    [ 'server',     $msg            ], 'server: requst is correct',
    [ 'server',     SENT            ], 'server: reply sent',
    [ 'client',     EOF             ], 'client: got eof',
    [ 'client',     "echo: $msg"    ], 'client: reply is correct',
);
plan tests => @CheckPoint/2;


my $srv_sock = tcp_server('127.0.0.1', 4444);
my $srv_w = EV::io($srv_sock, EV::READ, sub {
    if (accept my $sock, $srv_sock) {
        checkpoint(ACCEPTED);
        IO::Stream->new({
            fh          => $sock,
            cb          => \&server,
            wait_for    => EOF,
            in_buf_limit=> 1024,
            out_buf     => $banner,
        });
    }
    elsif ($! != EAGAIN) {
        die "accept: $!\n";
    }
});

IO::Stream->new({
    host        => '127.0.0.1',
    port        => 4444,
    cb          => \&client,
    wait_for    => IN,
    in_buf_limit=> 1024,
});

EV::loop;


sub server {
    my ($io, $e, $err) = @_;
#  &diag_event;
    checkpoint($e);
    if ($err) {
        die $err;
    }
    if ($e & EOF) {
        checkpoint($io->{in_buf});
        $io->{wait_for} = EOF|SENT;
        $io->write("echo: $io->{in_buf}");
    }
    if ($e & SENT) {
        shutdown $io->{fh}, 1;
    }
}

sub client {
    my ($io, $e, $err) = @_;
#  &diag_event;
    checkpoint($e);
    if ($e & IN) {
        checkpoint($io->{in_buf});
        $io->{in_buf} = q{};
        $io->{wait_for} = SENT|EOF;
        $io->write($msg);
    }
    if ($e & SENT) {
        shutdown $io->{fh}, 1;
    }
    if ($e & EOF) {
        checkpoint($io->{in_buf});
        exit;
    }
}

