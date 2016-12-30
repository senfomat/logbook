package Kelp::Module::Logbook::Database;
use Kelp::Base 'Kelp::Module';

use common::sense;
use warnings;
use Carp;

use DBIx::Connector;

sub build {
	my ($self, %args) = @_;

	my $__conn = DBIx::Connector->new(
			$args{'dsn'},
			$args{'user'},
			$args{'password'},
			$args{'arguments'},
		);

	$__conn->mode('fixup');

	$self->register(
			dbconn	=> $__conn,
		);
}

1;
