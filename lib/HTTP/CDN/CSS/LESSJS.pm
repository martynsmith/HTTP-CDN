package HTTP::CDN::CSS::LESSJS;

use strict;
use warnings;
use HTTP::CDN::CSS;
use IPC::Open2;

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

    my ($child_out, $child_in);
    my $pid = open2($child_out, $child_in, 'lessc', '-');
    print $child_in $fileinfo->{data};
    close $child_in;
    local $/ = undef;
    $fileinfo->{data} = <$child_out>;

    $fileinfo->{mime} = $HTTP::CDN::mimetypes->type('text/css');
}

1;
