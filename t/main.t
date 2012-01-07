#!perl
use Test::Most;

use strict;
use warnings;

use autodie;
use Test::DZil;
use LWP::UserAgent;

# Check if we can get to CPAN, skip if not
my $ua = LWP::UserAgent->new(keep_alive => 1);
$ua->env_proxy;
my $res = $ua->get("http://cpanidx.org/cpanidx/json/mod/Dist-Zilla-Plugin-CheckVersionIncrement");
if (!$res->is_success) {
    plan skip_all => 'Cannot access CPAN index';
}

# This needs to be the name of an actual module on CPAN. May as well
# be this one.
my $module_text = <<'MODULE';
package Dist::Zilla::Plugin::CheckVersionIncrement;
# Lowest version possible
$Dist::Zilla::Plugin::CheckVersionIncrement::VERSION = '0.000001';
1;
MODULE

my $tzil = Builder->from_config(
    { dist_root => 'corpus/empty' },
    {
        add_files => {
            'source/Dist/Zilla/Plugin/CheckVersionIncrement.pm' => $module_text,
            'source/dist.ini' => dist_ini({
                    name     => 'Dist-Zilla-Plugin-CheckVersionIncrement',
                    abstract => 'Testing CheckVersionIncrement',
                    version  => '0.000001',
                    author   => 'E. Xavier Ample <example@example.org>',
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                }, (
                    'CheckVersionIncrement',
                    'GatherDir',
                    'FakeRelease',
                )
            ),
        },
    }
);

throws_ok { $tzil->release; } qr/aborting release because a higher version number is already indexed on CPAN/, 'Aborted as expected';

done_testing(1);
