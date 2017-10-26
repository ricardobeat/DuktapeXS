use 5.018002;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'DuktapeXS',
    VERSION_FROM   => 'lib/DuktapeXS.pm',
    PREREQ_PM      => {
        'Test::More' => 0,
        'Test::Output' => 0,
        'Test::Exception' => 0,
        'Exporter' => '5.57',
        'JSON' => 0,
    },
    ABSTRACT_FROM  => 'lib/DuktapeXS.pm',
    AUTHOR         => 'Ricardo Tomasi <ricardobeat@gmail.com>',
    LIBS           => [],
    # C              => ["duktape/duktape.c"],
    # H              => ["duktape/duktape.h", "duktape/duk_config.h"],
    DEFINE         => '',
    # OPTIMIZE       => '-O3',
    INC            => '-I.',
	OBJECT         => '$(O_FILES)',
);
