#!/usr/bin/env perl
use strict;
use warnings;

use feature 'say';

use Iron::TCP;
use Iron::SSL;
use LWP::UserAgent;

my $tcp = Iron::SSL->new(hostport => 'www.example.org:443');
$tcp->send("GET / HTTP/1.1\r\nHost: www.example.org\r\nConnection: close\r\n\r\n\r\n");
say $tcp->read_first;

# my $ua = LWP::UserAgent->new;
# my $res = $ua->get('http://www.example.org');
# say $res->content;
