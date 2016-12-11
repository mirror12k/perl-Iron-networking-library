package Iron::TCP;
use strict;
use warnings;

use feature 'say';

use IO::Socket::INET;
use Time::HiRes 'usleep';


=pod

=head1 Iron::TCP

a class wrapper around IO::Socket::INET to simplify non-blocking use.

=cut



sub wait_timeout (&$;$) {
	my ($method, $timeout, $interval) = @_;
	$interval //= 50;

	my $time = 0;
	while ($time < $timeout) {
		my $ret = $method->();
		return $ret if defined $ret;
		usleep ($interval * 1000);
		$time += $interval
	}
	return
}

=head2 Iron::TCP->new(%args)

if no 'sock' argument is specifed, creates a new IO::Socket::INET socket object in non-blocking mode with the given 'hostport' argument.
the constructor will wait $tcp->{timeout} milliseconds for the socket to connect.
if socket creation/connection failed, ->new will return undefined.
optional arguments:

=over

=item socket_options

an optional hash of options passed to IO::Socket::INET's constructor

=item timeout

specified the number of milliseconds until the socket will return a timeout. defaults to 5000 milliseconds

=back

=cut

sub new {
	my ($class, %args) = @_;
	my $self = bless { %args }, $class;

	$self->{sock} //= IO::Socket::INET->new (
		Proto => 'tcp',
		PeerAddr => $self->{hostport},
		# LocalPort => $self->{localport},
		Blocking => 0,
		%{$self->{socket_options}},
	) or return;
	$self->{timeout} //= 5000; # 5000 ms
	return unless wait_timeout { return $self->{sock}->connected } $self->{timeout};
	say "connected";

	return $self
}

=head2 $tcp->connected

returns a false-value if the socket hasn't been connected or if connection has been terminated gracefully

=cut

sub connected { eof $_[0]{sock} }

=head2 $tcp->close

closes the socket

=cut

sub close { $_[0]{sock}->close }

=head2 $tcp->read_data($length // 4096, $timeout // $tcp->{timeout})

reads data from the socket up to $length amount. if the read timeouts, it will simply return everything it already has

=cut

sub read_data {
	my ($self, $length, $timeout) = @_;
	$length //= 4096;
	$timeout //= $self->{timeout};

	my $data = '';
	wait_timeout {
		my $buffer;
		my $len = read ($self->{sock}, $buffer, $length - length $data) or return;
		# say "got len $len, is_connected? ", $self->connected;
		$data .= $buffer;
		return $data if $length == length $data;
		return
	} $timeout;

	return $data
}

=head2 $tcp->read_first($length // 4096, $timeout // $tcp->{timeout})

reads data from the socket up to $length amount. this method will specifically look for the first sequence of readable data,
and will not wait anymore after it has received the first piece, returning anything it already has.
useful when you don't need the whole chunk of data immediately (e.g. an HTTP header)

=cut

sub read_first {
	my ($self, $length, $timeout) = @_;
	$length //= 4096;
	$timeout //= $self->{timeout};

	my $data = '';
	wait_timeout {
		my $buffer;
		my $len = read ($self->{sock}, $buffer, $length - length $data);
		# say "got len $len, is_connected? ";
		if ($len) {
			$data .= $buffer;
		} elsif (length $data > 0) {
			return $data
		} else {
			return
		}
		return $data if $length == length $data;
		return
	} $timeout;

	return $data
}

=head2 $tcp->read_timeout($length, $timeout // $tcp->{timeout})

reads $length data from the socket. if the socket timeouts before it is able to read $length data, it will return undef.
useful when strict data sizes are required, and where returning partial data is a critical failure

=cut

sub read_timeout {
	my ($self, $length, $timeout) = @_;
	$timeout //= $self->{timeout};

	my $data = '';
	return wait_timeout {
		my $buffer;
		my $len = read ($self->{sock}, $buffer, $length - length $data) or return;
		$data .= $buffer;
		return $data if $length == length $data;
		return
	} $timeout
}

=head2 $tcp->send($msg)

sends $msg data through the socket

=cut

sub send {
	my ($self, $msg) = @_;
	$self->{sock}->print($msg);
}

=head2 $tcp->request($msg, $recv_length // 4096)

sends $msg data through the socket and uses read_data to get a response back.
useful for simple request/response instances

=cut

sub request {
	my ($self, $msg, $recv_length) = @_;

	$self->print($msg);

	return $self->read_data($recv_length)
}



1
