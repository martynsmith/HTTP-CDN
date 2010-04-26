use strict;
use warnings;

use Test::More tests => 8;
use Digest::MD5 qw(md5_hex);

my %MD5_FOR = (
    'style.css'      => '8b7164f64651ea7abed61131a749d7b0',
    'background.gif' => '01d4003e8bf0191d38ff170f613e47f0',
);

BEGIN { use_ok('HTTP::CDN') };

# dynamic init
HTTP::CDN->dynamic_manifest('dynamic', 't/data/', { base => 'cdn/' });

# static init
mkdir 't/cdn/';
HTTP::CDN->generate_manifest('t/data', 't/cdn', 't/manifest.json');
HTTP::CDN->generate_manifest('t/data/', 't/cdn/', 't/manifest.json');
HTTP::CDN->load_manifest('static', 't/manifest.json', 'cdn/');

eval { HTTP::CDN->generate_manifest('t/data/', 't/non-existing-path', 't/manifest.json'); };
like($@, qr/Invalid dst_path/);

eval { HTTP::CDN::dynamic->uri('404.pants'); };
like($@, qr/Invalid file extension: pants/);

eval { HTTP::CDN::static->uri('404.pants'); };
like($@, qr/Couldn't find file: 404.pants/);

eval { HTTP::CDN::dynamic->uri(); };
like($@, qr/No URI specified in lookup/);

eval { HTTP::CDN::static->uri(); };
like($@, qr/No URI specified in lookup/);

eval { HTTP::CDN::dynamic->uri('404.css'); };
like($@, qr/Couldn't find file: 404.css/);

eval { HTTP::CDN::static->uri('404.css'); };
like($@, qr/Couldn't find file: 404.css/);


# static cleanup
unlink 't/manifest.json';
system('rm', '-rf', 't/cdn');
