
package Regexp::Object;

use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Purity = 1;

use base qw/Exporter/;

our @EXPORT = qw/
		terminal union seq star plus opt count NO_BOUND capture capture_all
/;

use Regexp::Object::State;
use Regexp::Object::Lambda;
use Regexp::Object::Terminal;

sub terminal ($) {
	my ($terminal) = @_;
	my $y = Regexp::Object::Lambda->new;
	my $t = Regexp::Object::Terminal->new(
			next => $y,
			end => $y);
	$t->terminal($terminal);
	return $t;
}

sub _fix_item ($) {
	my ($item) = @_;
	unless (ref($item) && UNIVERSAL::isa($item, 'Regexp::Object::State')) {
		$item = terminal($item);
	}
	return $item;
}

sub union (@) {
	my (@items) = @_;
	my $y = Regexp::Object::Lambda->new;
	for my $item (@items) {
		$item = _fix_item($item);
		$item->end->next($y);
	}
	my $start = Regexp::Object::Lambda->new;
	$start->next(@items);
	$start->end($y);
	return $start;
}

sub seq (@) {
	my (@items) = @_;
	for my $item (@items) {
		$item = _fix_item($item);
	}
	if (@items > 1) {
		for my $i (0 .. @items - 2) {
			$items[$i]->end->next($items[$i + 1]);
		}
	}
	my $y = Regexp::Object::Lambda->new;
	if (@items) {
		$items[$#items]->end->next($y);
		$items[0]->end($y);
		return $items[0];
	}
	else {
		$y->end($y);
		return $y;
	}
}

sub star (@) {
	my (@items) = @_;
	my $state = seq(@items);
	my $end = Regexp::Object::Lambda->new;
	my $start = Regexp::Object::Lambda->new;
	$start->next($state, $end);
	$state->end->next($start);
	$start->end($end);
	return $start;
}

##
# TODO
#
# Make this clone less drastic.
#
# One idea: in places where we clone the same value in a loop, we should save
# the dumped string so that at each loop iteration we only have to eval the
# string.
##
sub clone {
	my ($item) = @_;
	my $VAR1;
	eval Dumper($item);
	return $VAR1;
}

sub plus (@) {
	my (@items) = @_;
	my $state = seq(@{clone(\@items)});
	return seq($state, star(clone($state)));
}

sub opt (@) {
	my (@items) = @_;
	my $state = seq(@items);
	my $nothing = Regexp::Object::Lambda->new;
	$nothing->end($nothing);
	return union($state, $nothing);
}

use constant NO_BOUND => -1;

sub count {
	my ($min, $max, @items) = @_;

	die if $min < -1 || $max < -1 || int($min) ne $min || int($max) ne $max;
	$min = NO_BOUND if $min == 0;

	if ($min == NO_BOUND && $max == NO_BOUND) {
		return star(@items);
	}
	else {
		my $state = seq(@items);
		if ($max == NO_BOUND) {
			return seq(count($min, $min, $state), star(clone($state)));
		}
		else {
			my @seqs;
			$min = 0 if $min == NO_BOUND;
			die if $max < $min;
			for my $cur ($min .. $max) {
				my @clones;
				if ($cur) {
					for my $i (1 .. $cur) {
						push @clones, clone($state);
					}
				}
				push @seqs, seq(@clones);
			}
			return union(@seqs);
		}
	}
}

sub _capture {
	my ($ctype, $name, @items) = @_;
	my $state = seq(@items);
	my $end = Regexp::Object::Lambda->new(end_capture => $name);
	$state->end->next($end);
	my $start = Regexp::Object::Lambda->new($ctype => $name);
	$start->next($state);
	$start->end($end);
	return $start;
}

sub capture ($@) {
	return _capture('start_capture', @_);
}

sub capture_all ($@) {
	return _capture('start_capture_all', @_);
}

1;

