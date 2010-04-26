use strict;
use warnings;

use Test::More tests => 3;
use Digest::MD5 qw(md5_hex);

my %MD5_FOR = (
    'style.css'      => '8b7164f64651ea7abed61131a749d7b0',
    'background.gif' => '01d4003e8bf0191d38ff170f613e47f0',
);

BEGIN { use_ok('HTTP::CDN') };

mkdir 't/cdn/';
HTTP::CDN->generate_manifest('t/data/', 't/cdn/', 't/manifest.json');

HTTP::CDN->load_manifest('static', 't/manifest.json', 'cdn/');

is(HTTP::CDN::static->uri('style.css'), 'cdn/style.B965717D76E0.css');

HTTP::CDN->load_manifest('barestatic', 't/manifest.json');

is(HTTP::CDN::barestatic->uri('style.css'), 'style.B965717D76E0.css');

unlink 't/manifest.json';
system('rm', '-rf', 't/cdn');
