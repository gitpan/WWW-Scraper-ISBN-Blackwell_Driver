#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'WWW::Scraper::ISBN::Blackwell_Driver',
    VERSION_FROM        => 'lib/WWW/Scraper/ISBN/Blackwell_Driver.pm',
    ABSTRACT            => q[Search driver for Blackwell's online book catalog],
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'WWW::Scraper::ISBN'            => '0.25',
        'WWW::Scraper::ISBN::Driver'    => '0.18',
        'WWW::Mechanize'                => '1.60',

        # build/test prereqs
        'Test::More'                    => '0.70',
        'IO::File'                      => '0'

    }
);
