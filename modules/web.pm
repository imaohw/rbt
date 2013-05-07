package web;

use strict;
use warnings;
use utf8;

use Encode;
use JSON;
use LWP::Simple;
use URI::Escape;

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

sub get_help {
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

    my $to = $event->{type} eq 'msg' ? $event->{nick} : $event->{to}[0];

    my $page = get("https://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=$st&safe=off");
    if($page) {
        my $data = JSON->new->utf8(0)->decode($page);
        if($data->{responseStatus} && $data->{responseStatus} == 200) {
            my $line = "Google: $data->{responseData}->{cursor}->{resultCount} Results";
            foreach(@{$data->{responseData}->{results}}) {
                $line .= " | $_->{unescapedUrl} - $_->{title}";
            }
            $line =~ s/<\/?b>//g;
            $con->privmsg($to, encode("utf8", $line));

            return;
        }
    }

    $con->privmsg($to, "I am very sorry but i broke Google");
}
1;
