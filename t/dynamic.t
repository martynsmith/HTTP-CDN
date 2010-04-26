use strict;
use warnings;

use Test::More tests => 11;
use Digest::MD5 qw(md5_hex);

my %MD5_FOR = (
    'style.css'      => 'b965717d76e00f9b0bbc44a373b69586',
    'script.js'      => '61d05c6e57b5cc82b8a316a19b332656',
    'background.gif' => '01d4003e8bf0191d38ff170f613e47f0',
);

BEGIN { use_ok('HTTP::CDN') };

HTTP::CDN->dynamic_manifest('dynamic', 't/data/', { base => 'cdn/' });

is(HTTP::CDN::dynamic->uri('style.css'), 'cdn/style.B965717D76E0.css');
is(HTTP::CDN::dynamic->uri('script.js'), 'cdn/script.61D05C6E57B5.js');
is(md5_hex(HTTP::CDN::dynamic->content('style.css')), $MD5_FOR{'style.css'});
is(md5_hex(HTTP::CDN::dynamic->content('script.js')), $MD5_FOR{'script.js'});
is(md5_hex(HTTP::CDN::dynamic->content('background.gif')), $MD5_FOR{'background.gif'});
my $info = HTTP::CDN::dynamic->info('style.css');
is($info->{hash}, 'B965717D76E0');
is($info->{extension}, 'css');
is($info->{mime}, 'text/css');


HTTP::CDN->dynamic_manifest('baredynamic', 't/data/');
is(HTTP::CDN::baredynamic->uri('style.css'), 'style.B965717D76E0.css');
is(HTTP::CDN::baredynamic->uri('script.js'), 'script.61D05C6E57B5.js');
