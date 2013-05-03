package web;

use strict;
use warnings;
use utf8;

use JSON;
use LWP::Simple;
use URI::Escape;

use Data::Dumper;

sub new {
    my $class = shift;
    my $config = shift;
    my $self = { _config => $config };
    bless($self, $class);
    return $self;
}

sub get_commands {
    my $self = shift;
    return { 'google' => \&web::_google };
}

sub get_event_handlers {
    my $self = shift;
    return {};
}

sub _google {
    my $self = shift;
    my $con = shift;
    my $event = shift;
    my $cl = shift;

    shift(@$cl);
    my $st = join(" ", @$cl);
    $st = uri_escape($st);

    my $page = get("https://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=$st&safe=off");
    if($page) {
        my $data = decode_json($page);
        if($data->{responseStatus} && $data->{responseStatus} == 200) {
            my $line = "Google: $data->{responseData}->{cursor}->{resultCount} Results";
            foreach(@{$data->{responseData}->{results}}) {
                $line .= " | $_->{unescapedUrl} - $_->{title}";
            }
            $line =~ s/<\/?b>//g;
            $con->privmsg($event->{to}[0], $line);

            return;
        }
    }

    $con->privmsg($event->{to}[0], "I am very sorry but i broke Google");
}
1;
