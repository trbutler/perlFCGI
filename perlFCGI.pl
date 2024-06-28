#!/usr/bin/perl
use strict;
use warnings;
use HTTP::Daemon;
use HTTP::Status;
use File::Path qw(make_path);

my $d = HTTP::Daemon->new( LocalPort => 8089 ) || die;

while (my $c = $d->accept) {
    while (my $r = $c->get_request) {

        my $response = HTTP::Response->new(RC_OK);
        $response->header('Content-Type' => 'text/plain');

                if ($r->uri->path eq "/makedir") {
                        `/bin/mkdir -p /tmp/fcgiwrap_sockets;`;
                        $response->content("Created Directory.");
                }
                elsif ($r->uri->path =~ m#^/spawnprocess/(.*)$#) {
                        my $script = '/' . $1;
                        my $scriptPath = $script =~ s/^(.*\/).*?$/\1/r;
                        print STDERR 'script: ' . $script . "\n";
                        print STDERR 'scriptPath: ' . $scriptPath . "\n";
                        make_path('/tmp/fcgiwrap_sockets' . $scriptPath);

                        my $pid = fork();

                        if ($pid == 0) {
                                my $socket = '/tmp/fcgiwrap_sockets' . $script . '.sock';
                                `spawn-fcgi -u user -s $socket -n -- /usr/bin/multiwatch -f 4 -- $script`;
                                my $command = "spawn-fcgi -s $socket -n -- /usr/bin/multiwatch -f 4 -- $script";
                                exit;
                        }
                        $response->content("\nSpawned process.");
                }

                $c->send_response( $response );
    }
    $c->close;
    undef($c);
}
