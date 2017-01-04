# Options specific to deployment only
{
	'modules_init' => {
		Logger => {
			outputs => [
				[
					'File',
					name      => 'error',
					filename  => 'log/error.log',
					min_level => 'error',
					mode      => '>>',
					newline   => 1,
					binmode   => ":encoding(UTF-8)"
				],
			]
		},

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
				mysql_enable_utf8	=> 1,
			}
		},

		'JSON::XS' => {
			pretty				=> 0,
			canonical			=> 0,
		},
	},
};
