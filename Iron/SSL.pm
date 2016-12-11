package Iron::SSL;
use parent 'Iron::TCP';
use strict;
use warnings;

use feature 'say';

use IO::Socket::SSL;



=pod

=head1 Iron::SSL

extension of Iron::TCP to wrap IO::Socket::SSL to simplify non-blocking use.
read the documentation of Iron::TCP to view all available funcitonality

=cut



=head2 Iron::SSL->new(%args)

if no 'sock' argument is specifed, creates a new IO::Socket::SSL socket object in non-blocking mode with the given 'hostport' argument.
if the 'no_ssl' argument is set to true, the socket will be an IO::Socket::INET socket.
if socket creation/connection failed, ->new will return undefined.
all other options/functionality can be found in Iron::TCP

=cut

sub new {
	my ($class, %args) = @_;

	# if no ssl is set, we don't create a socket here, but instead hand it over to SimpleTCP which will create a normal INET socket
	unless ($args{no_ssl}) {
		$args{sock} //= IO::Socket::SSL->new (
			Proto => 'tcp',
			PeerAddr => $args{hostport},
			# LocalPort => $args{localport},
			Blocking => 0,
			%{$args{socket_options}},
		) or return;
	}

	my $self = $class->SUPER::new(%args) or return;

	return $self
}


=head2 see also

Iron::TCP

=cut


1;
