#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Mojolicious::Plugin::ValidateTiny',
    VERSION_FROM => 'lib/Mojolicious/Plugin/ValidateTiny.pm',
    AUTHOR       => 'Viktor Turskyi <koorchik@cpan.org>',
    PREREQ_PM    => {
        'Mojolicious'    => 2.42,
        'Validate::Tiny' => 0.08
    },
    PREREQ_PRINT => 1,
    test => { TESTS => 't/*.t' },
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojolicious-Plugin-ValidateTiny-*' },
    
);
