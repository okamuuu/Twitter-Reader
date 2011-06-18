package Twitter::Reader;
use 5.010;
use strict;
use warnings;
our $VERSION = '0.01';

use Net::Twitter;
use URI::Find;
use Web::Scraper;
use LWP::UserAgent;
use YAML;
use Scalar::Util 'blessed';
use Encode;

sub get_list_statuses {
    my ( $class, $nt, $list, $page ) = @_;
    my $statuses;
    my $success = 1;
    eval {
        $statuses = $nt->list_statuses(
            {
                user     => $list->{user},
                list_id  => $list->{list_id},
                per_page => 200,
                page     => $page,
                since_id => $list->{since_id}
            }
        );
    };
    if ( my $err = $@ ) {
        die $@ unless blessed $err && $err->isa('Net::Twitter::Error');
        $success = undef;
    }
    return ( $statuses, $success );
}

sub find_uris_from {
    my ( $class, $text ) = @_;
    state @uris;
    @uris = ();
    state $finder = URI::Find->new(
        sub {
            my ( $uri, $orig_uri ) = @_;
            push @uris, $orig_uri;
            return $orig_uri;
        }
    );
    $finder->find( \$text );
    return @uris;
}

sub expand_uri {
    my ( $class, $ua, $uri ) = @_;
    my $res = $ua->head($uri);
    return unless $res->is_success;
    return $res->request->uri;
}

sub get_html_title {
    my ( $class, $uri ) = @_;
    state $scraper = scraper {
        process 'title', 'title' => 'TEXT';
    };
    my $html;
    eval { $html = $scraper->scrape( URI->new($uri) ); };
    return if $@;
    return "-- No title --" unless $html->{title};
    return $html->{title};
}

1;

__END__

=head1 NAME

Twitter::Reader -

=head1 SYNOPSIS

  use Twitter::Reader;

=head1 DESCRIPTION

Twitter::Reader is

=head1 AUTHOR

okamura E<lt>default {at} example.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

