use strict;
use warnings;

use Test::More tests => 3;
use Digest::MD5 qw(md5_hex);

my $style_md5      = uc substr('9b80457103663b3b70280fa871253d4f',0,12);
my $style_bare_md5 = uc substr('f2b1f6b6fdac76a8748f4d610b321554',0,12);

BEGIN { use_ok('HTTP::CDN') };

mkdir 't/cdn/';
HTTP::CDN->generate_manifest('t/data/', 't/cdn/', 't/manifest.json');

HTTP::CDN->load_manifest('static', 't/manifest.json', 'cdn/');

is(HTTP::CDN::static->uri('style.css'), "cdn/style.$style_md5.css");

HTTP::CDN->load_manifest('barestatic', 't/manifest.json');

is(HTTP::CDN::barestatic->uri('style.css'), "style.$style_bare_md5.css");

unlink 't/manifest.json';
system('rm', '-rf', 't/cdn');
