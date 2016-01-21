use inc::Module::Install;

name     'IO-Stream';
all_from 'lib/IO/Stream.pm';
author   'Alex Efros <powerman-asdf@ya.ru>';
license  'perl';

# hardcode constant to optimize away needless code
use File::Spec;
my $WIN32 = $^O =~ /Win32/i ? 1 : 0;
system $^X, '-i.bak', '-pe', "s/(WIN32\\s*=>)\\s*\\d+/\$1 $WIN32/",
    File::Spec->catfile(qw( lib IO Stream const.pm ));
unlink File::Spec->catfile(qw( lib IO Stream const.pm.bak ));

requires 'version';
requires 'EV';
if (!$WIN32) {
requires 'EV::ADNS';
}

test_requires 'Test::More';
test_requires 'Test::Exception';

recommends 'Data::Alias' => '0.08';

my $online = prompt 'Run tests which require internet connection', 'n';
$online = lc $online eq 'y' ? 'y' : 'n';
open my $f, '>', 't/config.pm' or die "open: $!";
printf {$f} "use constant CFG_ONLINE => '%s';\n", $online;
printf {$f} '1;';
close $f or die "close: $!";

auto_install;

WriteAll;

