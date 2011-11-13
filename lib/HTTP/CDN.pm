package HTTP::CDN;

use strict;
use warnings;

our $VERSION = '0.3';

use Moose;
use Moose::Util::TypeConstraints;

use URI;
use Path::Class;
use MIME::Types;
use Digest::MD5;
use Module::Load;

our $mimetypes = MIME::Types->new;
our $default_mimetype = $mimetypes->type('application/octet-stream');

use constant EXPIRES => 315_576_000; # ~ 10 years

subtype 'HTTP::CDN::Dir' => as class_type('Path::Class::Dir');
subtype 'HTTP::CDN::URI' => as class_type('URI');

coerce 'HTTP::CDN::Dir' => from 'Str' => via { Path::Class::dir($_)->resolve->absolute };
coerce 'HTTP::CDN::URI' => from 'Str' => via { URI->new($_) };

has 'plugins' => (
    traits   => ['Array'],
    isa      => 'ArrayRef[Str]',
    required => 1,
    default  => sub { [qw(HTTP::CDN::CSS)] },
    handles  => {
        plugins => 'elements',
    },
);
has 'base' => (
    isa      => 'HTTP::CDN::URI',
    is       => 'rw',
    required => 1,
    coerce   => 1,
    default  => sub { URI->new('') },
);
has 'root' => (
    isa      => 'HTTP::CDN::Dir',
    is       => 'ro',
    required => 1,
    coerce   => 1,
);
has '_cache' => (
    isa      => 'HashRef',
    is       => 'ro',
    required => 1,
    default  => sub { {} },
);

sub BUILD {
    my ($self) = @_;

    my @plugins;

    foreach my $plugin ( $self->plugins ) {
        eval { load "HTTP::CDN::$plugin" };
        if ( $@ ) {
            load $plugin;
        }
        else {
            $plugin = "HTTP::CDN::$plugin";
        }
        push @plugins, $plugin;
    }
    $self->{plugins} = \@plugins;
}

sub to_plack_app {
    my ($self) = @_;

    load 'Plack::Request';
    load 'Plack::Response';

    return sub {
        my $request = Plack::Request->new(@_);
        my $response = Plack::Response->new(200);

        my ($uri, $hash) = $self->unhash_uri($request->path);

        my $info = eval { $self->fileinfo($uri) };

        unless ( $info and $info->{hash} eq $hash ) {
            $response->status(404);
            $response->content_type( 'text/plain' );
            $response->body( 'HTTP::CDN - not found' );
            return $response->finalize;
        }

        $response->status( 200 );
        $response->content_type( $info->{mime}->type );
        $response->headers->header('Last-Modified' => HTTP::Date::time2str($info->{stat}->mtime));
        $response->headers->header('Expires' => HTTP::Date::time2str(time + EXPIRES));
        $response->headers->header('Cache-Control' => 'max-age=' . EXPIRES . ', public');
        $response->body($self->filedata($uri));
        return $response->finalize;
    }
}

sub unhash_uri {
    my ($self, $uri) = @_;

    unless ( $uri =~ s/\.([0-9A-F]{12})\.([^.]+)$/\.$2/ ) {
        return;
    }
    my $hash = $1;
    return wantarray ? ($uri, $hash) : $uri;
}

sub cleanup_uri {
    my ($self, $uri) = @_;

    return $self->root->file($uri)->cleanup->relative($self->root);
}

sub resolve {
    my ($self, $uri) = @_;

    my $fileinfo = $self->update($uri);

    return $self->base . $fileinfo->{components}{cdnfile};
}

sub fileinfo {
    my ($self, $uri) = @_;

    return $self->update($uri);
}

sub filedata {
    my ($self, $uri) = @_;

    return $self->_fileinfodata($self->update($uri));
}

sub _fileinfodata {
    my ($self, $fileinfo) = @_;

    return $fileinfo->{data} // scalar($fileinfo->{fullpath}->slurp);
}

sub update {
    my ($self, $uri) = @_;

    die "No URI specified" unless $uri;

    my $force_update;

    my $fragment = $1 if $uri =~ s/(#.*)//;

    my $file = $self->cleanup_uri($uri);

    my $fileinfo = $self->_cache->{$file} ||= {};

    unless ( $fragment ~~ $fileinfo->{components}{fragment} ) {
        $fileinfo->{components}{fragment} = $fragment;
        $force_update = 1;
    }

    my $fullpath = $fileinfo->{fullpath} //= $self->root->file($file);

    my $stat = $fullpath->stat;

    die "Failed to stat $fullpath" unless $stat;

    my $mime = $fileinfo->{mime} //= $mimetypes->mimeTypeOf($file) // $default_mimetype;

    unless ( not $force_update and $fileinfo->{stat} and $fileinfo->{stat}->mtime == $stat->mtime ) {
        delete $fileinfo->{data};
        $fileinfo->{dependancies} = {};

        $fileinfo->{components} = do {
            my $extension = "$file";
            $extension =~ s/(.*)\.//;
            {
                file      => "$file",
                extension => $extension,
                barename  => $1,
                fragment  => $fileinfo->{components}{fragment},
            }
        };

        foreach my $plugin ( $self->plugins ) {
            next unless $plugin->can('preprocess');
            $plugin->can('preprocess')->($self, $file, $stat, $fileinfo);
        }

        # Need to update this file
        $fileinfo->{hash} = $self->hash_fileinfo($fileinfo);
        $fileinfo->{components}{cdnfile} = join('.', $fileinfo->{components}{barename}, $fileinfo->{hash}, $fileinfo->{components}{extension});
        $fileinfo->{components}{cdnfile} .= $fileinfo->{components}{fragment} if $fileinfo->{components}{fragment};
    }
    # TODO - need to check dependancies?

    $fileinfo->{stat} = $stat;

    return $fileinfo;
}

sub hash_fileinfo {
    my ($self, $fileinfo) = @_;

    return uc substr(Digest::MD5::md5_hex(scalar($self->_fileinfodata($fileinfo))), 0, 12);
}

1;
