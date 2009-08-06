
package Regexp::Object::Test::Literal;

use strict;
use warnings;

sub new {
	my ($class, $literal) = @_;
	return bless \$literal, $class;
}

sub match {
	my ($self, $input) = @_;
	return $input eq $$self ? $input : undef;
}

1;

