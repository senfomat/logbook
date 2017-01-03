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
			DBinsertEntry => sub {
				my ($self, $options) = @_;

				my $table = $options->{ 'table' };

				my @fields;
				my @vals;

				while(my ($field, $val) = each(%{ $options->{ 'data' } })) {
					push @fields, $field;
					push @vals, $val;
				}

				my $dbh = $self->dbconn->dbh;

				my $stmt = $dbh->prepare_cached(qq{
						INSERT INTO
							$table
						SET } . join('=?,', @fields) .  qq{=?});
				$stmt->execute(@vals);
				$stmt->finish();

				$dbh->{'mysql_insertid'};
			},
			DBupdateEntry => sub {
				my ($self, $options) = @_;

				my $table = $options->{ 'table' };
				my $whereField = $options->{ 'whereField' };

				my @fields;
				my @vals;

				while(my ($field, $val) = each(%{ $options->{ 'data' } })) {
					push @fields, $field;
					push @vals, $val;
				}

				push @vals, $options->{ 'entryID' };

				my $stmt = $self->dbconn->dbh->prepare_cached(qq{
						UPDATE
							$table
						SET } . join('=?,', @fields) .  qq{=?
						WHERE
							$whereField = ?
					});
				$stmt->execute(@vals);
				$stmt->finish();
			}
		);
}

1;
