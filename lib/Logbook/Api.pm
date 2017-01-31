package Logbook::Api;

use common::sense;
use warnings;
use DateTime;

use DBI qw(:sql_types);
use Text::ParseWords;

sub GETlogentries {
	my ($self) = @_;

	my $dbh = $self->dbconn->dbh;
	my $retHash = {};

	my $dts;

	# Start-Timestamp either in http-Param 't' or the current month
	{
		if ($self->param('t')) {
			my ($year, $month) = split('-', $self->param('t'));
			$dts = DateTime->new(
					year	=> $year,
					month	=> $month,
					day		=> 1,
				);
		}
		else {
			$dts = DateTime->now->set_day(1);
		}
	}

	my $dte;

	# End-Timestamp either in http-Param 'e' or the next month
	{
		if ($self->param('e')) {
			my ($year, $month) = split('-', $self->param('e'));
			$dte = DateTime->new(
					year	=> $year,
					month	=> $month,
					day		=> 1,
				);
		}
		else {
			$dte = $dts->clone->add(months => 1);
		}
	}

	my $entriesArray;

	if ($self->param('q')) {
		my $conditions = _generateSearchWhere($self->param('q'), $dbh);

		if (exists $conditions->{ 'error' }) {
			push @{ $retHash->{ 'errortext' } }, @{ $conditions->{ 'error' } };
		}

		my $whereStatement = '';

		# Fetch list of entry_id's when category-filters are given
		if (exists $conditions->{ 'categories' }) {
			# TODO: beautify sql, very quirky (group by with dynamic count, brr)
			my $tmpHash = $dbh->selectall_hashref(q{
						SELECT
							entry_id
						FROM
							entry2categories
						WHERE
							category_id IN (} . join(',', @{ $conditions->{ 'categories' } }) . q{)
						GROUP BY entry_id HAVING COUNT(*) > } . (scalar(@{ $conditions->{ 'categories' } }) - 1),
					'entry_id'
				);

			if (scalar(keys %$tmpHash)) {
				$whereStatement .= ' AND entry_id IN (' . join(',', keys %$tmpHash) . ') ';
			}
		}

		if (exists $conditions->{ 'textfilter' }) {
			$whereStatement .= ' AND (' . join(' OR ', @{  $conditions->{ 'textfilter' } }) . ')';
		}

		my $stmt = $dbh->prepare(qq{
				SELECT
					entry_id,
					edate,
					title,
					description,
					author
				FROM
					entries
				WHERE
					edate BETWEEN ? AND ?
					$whereStatement
				ORDER BY
					edate DESC
			});

		$stmt->bind_param(1, $dts->ymd, SQL_DATETIME);
		$stmt->bind_param(2, $dte->ymd, SQL_DATETIME);
		$stmt->execute();

		$entriesArray = $stmt->fetchall_arrayref({});
	}
	else {
		my $stmt = $dbh->prepare_cached(q{
				SELECT
					entry_id,
					edate,
					title,
					description,
					author
				FROM
					entries
				WHERE
					edate BETWEEN ? AND ?
				ORDER BY
					edate DESC
			});

		$stmt->bind_param(1, $dts->ymd, SQL_DATETIME);
		$stmt->bind_param(2, $dte->ymd, SQL_DATETIME);
		$stmt->execute();

		$entriesArray = $stmt->fetchall_arrayref({});
	}

	my $cat_stmt = $dbh->prepare_cached(qq{
			SELECT
				category_id
			FROM
				entry2categories
			WHERE
				entry_id = ?
		});

	foreach my $entry (@$entriesArray) {
		$cat_stmt->execute($entry->{ 'entry_id' });

		while(my ($category_id) = $cat_stmt->fetchrow_array) {
			push @{ $entry->{ 'categories' } }, $category_id;
		}
	}

	$retHash->{ 'data' } = $entriesArray;

	my $prevMonth = $dts->clone->subtract(months => 1);
	my $nextMonth = $dts->clone->add(months => 1);

	$retHash->{ 'pagination' } = {
		prev_month		=> $prevMonth->ymd,
		cur_month			=> $dts->ymd,
		next_month		=> $nextMonth->ymd,
	};

	return $retHash;
}

sub GETcategories {
	my ($self) = @_;

	return $self->dbconn->dbh->selectall_hashref(qq{
						SELECT
							category_id,
							title,
							description,
							color,
							cgroup
						FROM
							categories
					},
					'category_id');
}

sub POSTnewlogentry {
	my ($self) = @_;

	my $params = $self->param;

	my $entry_id = $self->DBinsertEntry({
			table	=> 'entries',
			data	=> {
				edate				=> $params->{ 'edate' },
				title				=> $params->{ 'title' },
				description	=> $params->{ 'description' } || undef,
				author			=> $params->{ 'author' },
			},
		});

	foreach my $category_id (@{ $params->{ 'categories' } }) {
		$self->DBinsertEntry({
				table	=> 'entry2categories',
				data	=> {
					entry_id	=> $entry_id,
					category_id	=> $category_id,
				},
			});
	}

	return {
		entry_id	=> $entry_id
	};
}

sub PUTupdatelogentry {
	my ($self, $entry_id) = @_;

	my $dbh = $self->dbconn->dbh;
	my $params = $self->param;

	$self->DBupdateEntry({
			table				=> 'entries',
			whereField	=> 'entry_id',
			entryID			=> $entry_id,
			data	=> {
				edate				=> $params->{ 'edate' },
				title				=> $params->{ 'title' },
				description	=> $params->{ 'description' } || undef,
				author			=> $params->{ 'author' },
			},
		});

	{
		my $catdel_stmt = $dbh->prepare_cached(qq{
				DELETE FROM
					entry2categories
				WHERE
					entry_id = ?
			});

		$catdel_stmt->execute($entry_id);

		foreach my $category_id (@{ $params->{ 'categories' } }) {
			$self->DBinsertEntry({
					table	=> 'entry2categories',
					data	=> {
						entry_id	=> $entry_id,
						category_id	=> $category_id,
					},
				});
		}
	}

	return {
		success	=> $self->jsBool(1),
	};
}

sub DELETElogentry {
	my ($self, $entry_id) = @_;

	my $dbh = $self->dbconn->dbh;

	$dbh->do(qq{
			DELETE FROM
				entries
			WHERE
				entry_id = ?
		}, undef, $entry_id);

	$dbh->do(qq{
			DELETE FROM
				entry2categories
			WHERE
				entry_id = ?
		}, undef, $entry_id);

	return {
		success	=> $self->jsBool(1),
	};
}

sub _generateSearchWhere {
	my ($qparam, $dbh) = @_;

	my @textArr;
	my @catnameArr;
	my $retHash = {};

	foreach my $word (shellwords($qparam)) {
		if ($word =~ m/^cat:(.+)$/) {
			push @catnameArr, $1;
		}
		else {
			$word =~ s/(?=[\\%_])/\\/g;

			push @textArr, qq{title LIKE "%$word%"};
			push @textArr, qq{description LIKE "%$word%"};
		}
	}

	my @categoriesArray;

	# Resolve Catnames to category-id
	{
		my $cat_stmt = $dbh->prepare_cached(q{
				SELECT
					category_id
				FROM
					categories
				WHERE
					title = ?
			});

		my $categoriesHash;

		foreach my $catName (@catnameArr) {
			$cat_stmt->execute($catName);

			my $found = 0;

			while(my ($category_id) = $cat_stmt->fetchrow_array) {
				$categoriesHash->{ $category_id } = 1;
				$found = 1;
			}

			if (!$found) {
				push @{ $retHash->{ 'error' } }, qq{Kategorie "$catName" nicht gefunden!};
			}
		}

		@categoriesArray = keys %$categoriesHash;
	}

	if (scalar(@categoriesArray)) {
		$retHash->{ 'categories' } = \@categoriesArray;
	}
	if (scalar(@textArr)) {
		$retHash->{ 'textfilter' } = \@textArr;
	}

	return $retHash;
}

1;
