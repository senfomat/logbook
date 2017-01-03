# Options specific to development only
{
	'modules_init' => {
		'Logbook::Database' => {
			dsn		=> 'DBI:mysql:database=logbook:127.0.0.1:3306;mysql_auto_reconnect=0;',
			user	=> 'logbook',
			password	=> 'logbook',
			arguments	=> {
				RaiseError	=> 1,
				PrintError	=> 1,
				PrintWarn		=> 0,
				TraceLevel	=> 0,
				AutoCommit	=> 1,
			}
		},

		'JSON::XS' => {
			pretty				=> 1,
			canonical			=> 1,
		},
	},
	'+middleware'	=> [
		qw/
			StackTrace
		/
	],
	middleware_init => {
		StackTrace => {
			force => 1
		}
	},
	appconfig => {
		devel	=> 1,
	},
};
