package HTTP::CDN::CSS::LESSJS;

use strict;
use warnings;
use HTTP::CDN::CSS;

$HTTP::CDN::mimetypes->addType(
    MIME::Type->new(
        type => 'text/less',
        extensions => ['less'],
    ),
);

sub preprocess {
    my ($cdn, $file, $stat, $fileinfo) = @_;

    return unless $fileinfo->{mime} and $fileinfo->{mime}->type eq 'text/less';

    $fileinfo->{data} = $cdn->_fileinfodata($fileinfo);
    $fileinfo->{data} =~ s{ \@import \s+ (["']) ([^"']+) \1 }{
        my ($quote, $uri) = ($1, $2);
        $uri .= '.less' unless $uri =~ /\.less$/;
        $uri = HTTP::CDN::CSS::url_replace($cdn, $file, $stat, $fileinfo, $quote, $uri);
        "\@import $uri";
    }egx;

    $fileinfo->{mime} = $HTTP::CDN::mimetypes->type('text/css');
}

1;
