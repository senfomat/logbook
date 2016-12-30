package Logbook::Api;

use common::sense;
use warnings;

sub GETlogentries {
	my ($self) = @_;

	my $dbh = $self->dbconn->dbh;

	# TBD make an argument
	my $minDate = '2016-12-24 00:00:00';

	my $stmt = $dbh->prepare_cached(qq{
			SELECT
				entry_id,
				edate,
				title,
				description,
				author
			FROM
				entries
			WHERE
				edate BETWEEN ? AND DATE_ADD(?, INTERVAL 1 MONTH)
			ORDER BY
				edate
		});

	my $cat_stmt = $dbh->prepare_cached(qq{
			SELECT
				category_id
			FROM
				entry2categories
			WHERE
				entry2categories.entry_id = ?
		});

	$stmt->bind_param(1, $minDate);
	$stmt->bind_param(2, $minDate);
	$stmt->execute();

	my @entries;

	while(my $tmpHash = $stmt->fetchrow_hashref) {
		$cat_stmt->execute($tmpHash->{ 'entry_id' });

		while(my ($category_id) = $cat_stmt->fetchrow_array) {
			$tmpHash->{ 'categories' }{ $category_id } = 1;
		}

		$cat_stmt->finish();

		push @entries, $tmpHash;
	}

	$stmt->finish();

	my $pagination = {
		today_page_url	=> $minDate,
		prev_page_url		=> '',
		next_page_url		=> '',
	};

	return {
		data				=> \@entries,
		pagination	=> $pagination,
	};
}

sub GETcategories {
	my ($self) = @_;

	return $self->dbconn->dbh->selectall_hashref(qq{
						SELECT
							category_id,
							title,
							description
						FROM
							categories
					},
					'category_id');
}

1;
