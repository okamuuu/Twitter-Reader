#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use lib 'lib';
use Twitter::Reader;
use Net::Twitter;
use URI::Find;
use Web::Scraper;
use LWP::UserAgent;
use YAML;
use Scalar::Util 'blessed';
use Encode;

use Data::Dumper;

my $config_uri ='conf/conf.yml';
my $config = YAML::LoadFile($config_uri);

my $nt = Net::Twitter->new(
    traits              => [qw/API::REST API::Lists/],
);
my $read_it_later = URI->new('https://readitlaterlist.com/v2/add');
my $ua = LWP::UserAgent->new;

for my $list ( @{$config->{lists}} ) {
    my $page = 1;
    my $start_since_id = $list->{since_id};
    my $new_since_id   = $start_since_id;
  LOOP_PAGE:
    while (1) {
        my ($statuses, $success) = Twitter::Reader->get_list_statuses($nt,$list, $page);

        $new_since_id = $start_since_id unless $success;
        last LOOP_PAGE unless @$statuses;
        for my $status (reverse @$statuses) {
            warn $status->{id};
            my @uris = Twitter::Reader->find_uris_from($status->{text});
            for my $uri (@uris) {
                my $expand_uri = Twitter::Reader->expand_uri($ua,$uri);
                next unless $expand_uri;
                warn my $html_title = Twitter::Reader->get_html_title($expand_uri);
                next unless $html_title;
                $read_it_later->query_form(
                    apikey   => $config->{read_it_later}{apikey},
                    username => $config->{read_it_later}{username},
                    password => $config->{read_it_later}{password},
                    url      => $expand_uri,
                    title    => sprintf "[TW]%s@%s / %s\n",
                                        $list->{list_name},
                                        $status->{user}{screen_name},
                                        $html_title,
                );
                my $res;
                eval {
                    $res = $ua->head("$read_it_later");
                };
                if ( $@ ) { warn $@; next; }
                if ($res->is_success) {
                    printf "[TW]%s@%s / %s (%s)\n",
                           $list->{list_name},
                           $status->{user}{screen_name},
                           encode('utf-8', $html_title),
                           $expand_uri;
                }
            }
            $new_since_id = $status->{id} if $new_since_id < $status->{id}; 
        }
        $page++;
    }
    $list->{since_id} = $new_since_id;
}

YAML::DumpFile($config_uri, $config);

exit();

