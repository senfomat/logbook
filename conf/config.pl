# Common settings
{
	modules	=> [
		qw/
			Logger
			Template::Toolkit
			JSON::XS
			Logbook::Database
			Logbook::Helper
		/
	],
	modules_init => {
		Logger => {
			outputs => [
				[
					'File',
					name      => 'debug',
					filename  => 'log/debug.log',
					min_level => 'debug',
					mode      => '>>',
					newline   => 1,
					binmode   => ":encoding(UTF-8)"
				], [
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

		'Template::Toolkit' => {
			ENCODING => 'utf8',
			INCLUDE_PATH => [qw{./views/}],
			RELATIVE => 1
		},

		'JSON::XS' => {
			allow_blessed	=> 1,
		},

		'Logbook::Helper' => {
		},

		'Logbook::Database' => {
		},
	},
	middleware	=> [
		qw/
			Deflater
			Static
		/
	],
	middleware_init	=> {
		Deflater => {
			content_type => 'application/json'
		},
		Static => {
			path => qr{^/(?:static|components)/},
			root => '.',
		},
	},
	appconfig => {
		title	=> 'Charité Abt. Netzwerk Logbuch',
	},
};
