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
			utf8		=> 1,
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
		title	=> 'Logbuch',
		company	=> 'Charité Abt. Netzwerk',
		buttons	=> [
			{
				title	=> 'Neuer Eintrag',
				css_bs_btn => 'btn-primary',
				arguments	=> {},
			},
			{
				title	=> 'Hardwaretausch/Netz',
				css_bs_btn => 'btn-info btn-xs',
				arguments	=> {
					title => 'Austausch Modul/Chassis in GERAETENAME',
					categories => [8, 45, 30, 37, 38, 39, 44],
					description => 'Typ (alt): XX\nSeriennummer (alt): XX\n\nTyp (neu): YY\nSeriennummer (neu): YY',
				},
			},
			{
				title	=> 'Hardwaretausch/Server',
				css_bs_btn => 'btn-info btn-xs',
				arguments => {
					title => 'Austausch Serverhardware GERAETENAME',
					categories => [10, 30],
					description => 'Alte Hardware: \nNeue Hardware: ',
				},
			},
		],
	},
};
