package Iron::TCP;
use strict;
use warnings;

use feature 'say';

use IO::Socket::INET;
use Time::HiRes 'usleep';



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

sub new {
	my ($class, %args) = @_;
	my $self = bless { %args }, $class;

	$self->{sock} //= IO::Socket::INET->new (
		Proto => 'tcp',
		PeerAddr => $self->{hostport},
		LocalPort => $self->{localport},
		Blocking => 0,
		%{$self->{socket_options}},
	) or return;
	$self->{timeout} //= 5000; # 5000 ms
	return unless wait_timeout { return $self->{sock}->connected } $self->{timeout};
	say "connected";

	return $self
}

sub connected { eof $_[0]{sock} }
sub close { $_[0]{sock}->close }

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

sub read_first {
	my ($self, $length, $timeout) = @_;
	$length //= 4096;
	$timeout //= $self->{timeout};

	my $data = '';
	wait_timeout {
		my $buffer;
		my $len = read ($self->{sock}, $buffer, $length - length $data);
		if (defined $len) {
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

sub send {
	my ($self, $msg) = @_;
	$self->{sock}->send($msg);
}

sub request {
	my ($self, $msg, $recv_length) = @_;

	$self->send($msg);

	return $self->read_data($recv_length // 4096)
}



1
