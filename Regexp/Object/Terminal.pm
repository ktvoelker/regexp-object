
package Regexp::Object::Terminal;
use Moose;
extends 'Regexp::Object::State';

use Moose::Util::TypeConstraints;

subtype 'Terminal'
	=> as 'Item'
	=> where { $_->can('match') };

has 'terminal' => (
	is => 'ro',
	isa => 'Terminal',
	required => 1
);

has 'next' => (
	is => 'rw',
	isa => 'Regexp::Object::State',
	predicate => 'has_next'
);

sub transition {
	my ($self, $input) = @_;
	die unless $self->has_next;
	return () unless defined $input;
	my $result = $self->terminal->match($input);
	return $result ? ([$result, $self->next]) : ();
}

1;

