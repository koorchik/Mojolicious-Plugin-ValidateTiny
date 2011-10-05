#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Mojolicious::Plugin::ValidateTiny',
    VERSION_FROM => 'lib/Mojolicious/Plugin/ValidateTiny.pm',
    AUTHOR       => 'Viktor Turskyi <koorchik@cpan.org>',
    PREREQ_PM    => {
        'Mojolicious'    => 1.90,
        'Validate::Tiny' => 0.08
    },
    test => { TESTS => 't/*.t' },
);
