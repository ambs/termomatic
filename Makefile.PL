use strict;
use warnings;
use ExtUtils::MakeMaker;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

WriteMakefile(
    NAME                => 'Termomatic',
    AUTHOR              => q{YOUR NAME <youremail@example.com>},
    VERSION_FROM        => 'lib/Termomatic.pm',
    ABSTRACT            => 'YOUR APPLICATION ABSTRACT',
    ($eumm_version >= 6.3001
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
                  'Test::More'  => '0',
                  'YAML'        => '0',
                  'Dancer2'     => '0.04',
                  'DBI'         => '0',
                  'Digest::SHA' => '0',
                  'Dancer2::Plugin::Emailesque'  => '0.001',
                  'Dancer2::Plugin::Deferred' => '0.004',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Termomatic-*' },
);
