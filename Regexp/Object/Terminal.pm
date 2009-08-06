
package Regexp::Object::Terminal;
use Moose;
extends 'Regexp::Object::State';

my $next_id = 0;
my @terminals;

has '_terminal_id' => (
	is => 'ro',
	isa => 'Int',
	required => 1,
	default => sub { return $next_id++; }
);

has 'next' => (
	is => 'rw',
	isa => 'Regexp::Object::State',
	predicate => 'has_next'
);

sub terminal {
	my ($self, $new) = @_;
	if (defined $new) {
		$terminals[$self->_terminal_id] = $new;
	}
	return $terminals[$self->_terminal_id];
}

sub transition {
	my ($self, $input, $expected) = @_;
	die unless $self->has_next;
	unless (defined $input) {
		push @$expected, $self->terminal
			unless grep { $_ == $self->terminal } @$expected;
		return ();
	}
	my $result = $self->terminal->match($input);
	return $result ? ([$result, $self->next]) : ();
}

1;

