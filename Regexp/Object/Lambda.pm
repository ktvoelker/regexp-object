
package Regexp::Object::Lambda;
use Moose;
extends 'Regexp::Object::State';

use Moose::Util::TypeConstraints;

subtype 'LambdaResult'
	=> as 'ArrayRef[Undef | Regexp::Object::State]'
	=> where { !defined $_->[0] && defined $_->[1] };

has '_next' => (
	is => 'rw',
	isa => 'ArrayRef[LambdaResult]',
	auto_deref => 1,
	predicate => 'has_next'
);

sub transition {
	my ($self, undef) = @_;
	return $self->_next;
}

sub accepting {
	my ($self) = @_;
	return !$self->has_next;
}

sub next {
	my ($self, @next) = @_;
	$self->_next([map { [undef, $_] } @next]);
}

1;

