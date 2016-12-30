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

		'JSON::XS' => {
			pretty				=> 0,
			canonical			=> 0,
		},
	},
};
