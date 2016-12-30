use lib 'lib';
use Logbook;

use Plack::Builder;
use Plack::Middleware::ReverseProxy;

my $app = Logbook->new();

builder {
	enable_if { (! defined $_[0]->{REMOTE_ADDR}) || ($_[0]->{REMOTE_ADDR} eq '127.0.0.1') } 'Plack::Middleware::ReverseProxy';
	$app->run;
};
