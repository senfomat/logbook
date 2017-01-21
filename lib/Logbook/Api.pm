package Logbook::Api;

use common::sense;
use warnings;
use DateTime;

use DBI qw(:sql_types);
use Text::ParseWords;

sub GETlogentries {
	my ($self) = @_;

	my $dbh = $self->dbconn->dbh;

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

	my $stmt;

	if ($self->param('q')) {
		my $whereStatement = _generateSearchWhere($self->param('q'), $dbh);

		$stmt = $dbh->prepare(qq{
				SELECT
					DISTINCT(entry_id),
					edate,
					title,
					description,
					author
				FROM
					entries
				LEFT JOIN entry2categories USING (entry_id)
				WHERE
					edate BETWEEN ? AND ?
					$whereStatement
				ORDER BY
					edate DESC
			});

		$stmt->bind_param(1, $dts->ymd, SQL_DATETIME);
		$stmt->bind_param(2, $dte->ymd, SQL_DATETIME);
	}
	else {
		$stmt = $dbh->prepare_cached(q{
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
	}

	my $cat_stmt = $dbh->prepare_cached(qq{
			SELECT
				category_id
			FROM
				entry2categories
			WHERE
				entry2categories.entry_id = ?
		});

	$stmt->execute();

	my @entries;

	while(my $tmpHash = $stmt->fetchrow_hashref) {
		$cat_stmt->execute($tmpHash->{ 'entry_id' });

		while(my ($category_id) = $cat_stmt->fetchrow_array) {
			push @{ $tmpHash->{ 'categories' } }, $category_id;
		}

		$cat_stmt->finish();

		push @entries, $tmpHash;
	}

	$stmt->finish();

	my $prevMonth = $dts->clone->subtract(months => 1);
	my $nextMonth = $dts->clone->add(months => 1);

	my $pagination = {
		prev_month		=> $prevMonth->ymd,
		cur_month			=> $dts->ymd,
		next_month		=> $nextMonth->ymd,
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

			while(my ($category_id) = $cat_stmt->fetchrow_array) {
				$categoriesHash->{ $category_id } = 1;
			}

			$cat_stmt->finish();
		}

		@categoriesArray = map { "category_id = $_" } keys %$categoriesHash;
	}

	my $retStr = '';
	if (scalar(@categoriesArray)) {
		$retStr .= ' AND (' . join(' OR ', @categoriesArray) . ')';
	}
	if (scalar(@textArr)) {
		$retStr .= ' AND (' . join(' OR ', @textArr) . ')';
	}

	return $retStr;
}

1;
