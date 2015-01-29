use 5.010;
use strict;
use warnings;

use Test::More tests => 13;
use Digest::MD5 qw(md5_hex);

my %MD5_FOR = (
    'background.gif' => '01d4003e8bf0191d38ff170f613e47f0',
    'script.js'      => '61d05c6e57b5cc82b8a316a19b332656',
    'style.css'      => 'ae963617e416e1e0aac7ee5092c254ff',
);

BEGIN { use_ok('HTTP::CDN') };

my $cdn = HTTP::CDN->new(
    root => 't/data',
    base => 'cdn/',
);

foreach my $file ( sort keys %MD5_FOR ) {
    my $expected = $file;
    my $hash = uc(substr($MD5_FOR{$file}, 0, 12));
    $expected =~ s/(.*)\.(.*)/"$1.$hash.$2"/e;
    is($cdn->resolve($file), "cdn/$expected", "Generates correct URI for $file");
}
is(md5_hex($cdn->filedata('style.css')), $MD5_FOR{'style.css'}, 'Hash correct for file style.css.');
is(md5_hex($cdn->filedata('script.js')), $MD5_FOR{'script.js'}, 'Hash correct for file script.js.');
is(md5_hex($cdn->filedata('background.gif')), $MD5_FOR{'background.gif'}, 'Hash correct for file background.gif.');
my $info = $cdn->fileinfo('style.css');
is($info->{hash}, uc substr($MD5_FOR{'style.css'},0,12));
is($info->{components}{extension}, 'css');
is($info->{mime}->type, 'text/css');

$cdn = HTTP::CDN->new(
    root => 't/data',
    base => '',
);

# For the bare dynamic the MD5 of the stylesheet changes (due to the root path
# being different)
$MD5_FOR{'style.css'} = 'b0e08aa6bda8d5c8a6be5d52bccf0de1';

foreach my $file ( sort keys %MD5_FOR ) {
    my $expected = $file;
    my $hash = uc(substr($MD5_FOR{$file}, 0, 12));
    $expected =~ s/(.*)\.(.*)/"$1.$hash.$2"/e;
    is($cdn->resolve($file), "$expected");
}
