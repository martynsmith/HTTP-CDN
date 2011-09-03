package HTTP::CDN::CSS;

use strict;
use warnings;
use URI;
use Path::Class;

sub preprocess {
    my ($cdn, $file, $stat, $fileinfo) = @_;

    return unless $fileinfo->{mime} and $fileinfo->{mime}->type eq 'text/css';

    $fileinfo->{data} = $cdn->_fileinfodata($fileinfo);
    $fileinfo->{data} =~ s{ url \( (["']?) ([^)]+) \1 \) }{ url_replace($cdn, $file, $stat, $fileinfo, $1, $2); }egx;
}

sub url_replace {
    my ($cdn, $file, $stat, $fileinfo, $quotes, $match) = @_;

    $match = URI->new($match);

    # Absolute links with a host just remain unchanged
    if ( $match->can('host') and $match->host ) {
        return "url(${quotes}${match}${quotes})";
    }

    # Absolute links with (i.e. those starting with /) are treated as
    # referencing the top of the CDN
    if ( $match->path_segments and ($match->path_segments)[0] eq '' ) {
        my $subinfo = $cdn->fileinfo($match);
        $fileinfo->{dependancies}{$subinfo->{components}{file}}++;
        my $new_url = $cdn->base . $subinfo->{components}{cdnfile};
        return "url(${quotes}${new_url}${quotes})";
    }

    # File is relative to the stylesheet
    my $subinfo = $cdn->fileinfo($fileinfo->{fullpath}->dir->file($match)->relative($cdn->root));

    $fileinfo->{dependancies}{$subinfo->{components}{file}}++;

    my $new_url = Path::Class::file($match)->dir->file(Path::Class::file($subinfo->{components}{cdnfile})->basename)->cleanup;

    return "url(${quotes}${new_url}${quotes})";
}

1;
