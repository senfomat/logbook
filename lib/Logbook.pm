package Logbook;
use Kelp::Base 'Kelp';

sub build {
	my $self = shift;
	my $routes = $self->routes;

	$routes->add('/', sub {
			my ($self) = @_;

			$self->template('index', {
					appconfig	=> ${ $self->config_hash }{ 'appconfig' },
					user		=> $self->req->env->{ 'HTTP_REMOTE_USER' },
				}
			);
		});

	$routes->add('/logentries' => {
		via	=> 'GET',
		to	=> 'Api#GETlogentries',
	});

	$routes->add('/logentry' => {
		via	=> 'POST',
		to	=> 'Api#POSTnewlogentry',
	});

	$routes->add('/logentry/:entry_id' => {
		via	=> 'PUT',
		to	=> 'Api#PUTupdatelogentry',
	});

	$routes->add('/logentry/:entry_id' => {
		via	=> 'DELETE',
		to	=> 'Api#DELETElogentry',
	});

	$routes->add('/categories' => {
		via	=> 'GET',
		to	=> 'Api#GETcategories',
	});

	if ($self->mode eq 'development') {
		$routes->add('/config', sub { $_[0]->config_hash } );
	}
}

1;
