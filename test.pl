#!/usr/bin/env perl
use strict;
use warnings;

use feature 'say';

use Iron::TCP;
use SimpleTCP;
use LWP::UserAgent;

my $tcp = Iron::TCP->new(hostport => 'www.example.org:80');
$tcp->send("GET / HTTP/1.1\r\nHost: www.example.org\r\nConnection: close\r\n\r\n\r\n");
say $tcp->read_timeout(4000);

# my $tcp = SimpleTCP->new(hostport => 'google.com:80');
# $tcp->send("GET / HTTP/1.1\r\nHost: google.com\r\nConnection: close\r\n\r\n\r\n");
# say $tcp->read_data;

# my $ua = LWP::UserAgent->new;
# my $res = $ua->get('http://www.example.org');
# say $res->content;