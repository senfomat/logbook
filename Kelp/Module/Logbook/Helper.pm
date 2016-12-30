package Kelp::Module::Logbook::Helper;
use Kelp::Base 'Kelp::Module';

use common::sense;
use warnings;
use Data::Dumper;

sub build {
	my ($self) = @_;

	$self->register(
			jsBool => sub {
				((! defined $_[1]) || ($_[1] == 0)) ? \0 : \1;
			},
			httpparamhash => sub {
				$_[0]->req->parameters->mixed;
			},
			dumper => sub {
				'<pre>' . Dumper($_[1]);
			},
		);
}

1;
