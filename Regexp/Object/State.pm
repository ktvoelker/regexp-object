
package Regexp::Object::State;
use Moose;

my $next_id = 0;

has 'id' => (
	is => 'ro',
	isa => 'Int',
	required => 1,
	default => sub {
		return $next_id++;
	}
);

has 'start_capture' => (
	is => 'ro',
	isa => 'Str'
);

has 'start_capture_all' => (
	is => 'ro',
	isa => 'Str'
);

has 'end_capture' => (
	is => 'ro',
	isa => 'Str'
);

has 'end' => (
	is => 'rw',
	isa => 'Regexp::Object::State'
);

##
# Given an input terminal or undef, return a list of pairs [X,Y] where X is an
# output terminal if the input terminal was consumed or undef otherwise, and
# where Y is the next state.
##
sub transition;

##
# Is this an accepting state?
##
sub accepting {
	return 0;
}

##
# Given a sequence of inputs, return a hash reference mapping each capture to
# its result, if the entire input matches the regexp, or undef otherwise.
##
sub match {
	my ($self, @input) = @_;
	my ($capture, $remain) = $self->_match(\@input, {}, {}, {});
	return undef unless $capture;
	die if @$remain;
	return $capture;
}

sub _clone_hash {
	my ($item) = @_;
	my %clone = map { ($_ => clone($item->{$_})) } keys %$item;
	return \%clone;
}

sub clone {
	my ($item) = @_;
	if (ref($item)) {
		if (ref($item) eq 'HASH') {
			return _clone_hash($item);
		}
		elsif (ref($item) eq 'ARRAY') {
			my @clone = map { clone($_) } @$item;
			return \@clone;
		}
		elsif (ref($item) eq 'SCALAR') {
			my $clone = $$item;
			return \$clone;
		}
	}
	return $item;
}

sub _match {
	my ($self, $input, $closed, $open, $open_all) = @_;
	print STDERR "Entered state " . $self->id . " with input @$input\n";
	
	##
	# Close captures
	##
	my $end;
	if ($end = $self->end_capture) {
		print STDERR "Closing capture $end\n";
		if ($open->{$end}) {
			$closed->{$end} = $open->{$end};
			delete $open->{$end};
		}
		elsif ($open_all->{$end}) {
			push @{$closed->{$end}}, $open_all->{$end};
			delete $open_all->{$end};
		}
		print STDERR "  Current captures: " .
				join(' ', keys %$open, keys %$open_all) . "\n";
	}

	if ($self->accepting) {
		if (@$input) {
			print STDERR "Dead end\n";
			return ();
		}
		else {
			print STDERR "Accepting: " . join(' ', keys %$closed) . "\n";
			return ($closed, $input);
		}
	}

	##
	# Open captures
	##
	$open->{$self->start_capture} = [] if $self->start_capture;
	$open_all->{$self->start_capture_all} = [] if $self->start_capture_all;

	##
	# Get the next states
	##
	my @input_all = @$input;
	my ($input_head, @input_tail) = @input_all;
	my @next_states_with_output = $self->transition($input_head);

	##
	# For each of the next states, transition to that state. If it returns
	# a defined value, return that value.
	##
	for my $next_state_with_output (@next_states_with_output) {
		my ($output, $state) = @$next_state_with_output;

		##
		# Clone the captures if there are multiple next states
		##
		my ($next_closed, $next_open, $next_open_all);
		if (@next_states_with_output > 1) {
			($next_closed, $next_open, $next_open_all) =
					(clone($closed), clone($open), clone($open_all));
		}
		else {
			($next_closed, $next_open, $next_open_all) = ($closed, $open, $open_all);
		}

		##
		# Append the output that we obtained to all the open captures, if there
		# was any.
		##
		if (defined $output) {
			for my $capture (values %$next_open, values %$next_open_all) {
				push @$capture, $output;
			}
		}

		##
		# Call the next state.
		##
		my $next_input = defined $output ? \@input_tail : \@input_all;
		my @args = ($next_input, $next_closed, $next_open, $next_open_all);

		if (@next_states_with_output > 1) {
			my @result = $state->_match(@args);

			##
			# If the state produced a defined result, return it.
			##
			return @result if @result;
		}
		else {
			##
			# Do a tail call
			##
			@_ = ($state, @args);
			goto &{$state->can('_match')};
		}

	}

	##
	# None of our next states accepted 
	##
	return ();
}

1;

