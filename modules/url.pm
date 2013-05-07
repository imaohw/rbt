package url;

use strict;
use warnings;
use utf8;

use LWP::UserAgent;

sub new {
    my $class = shift;
    my $config = shift;
    my $self = { _config => $config };
    bless($self, $class);
    return $self;
}

sub get_commands {
    my $self = shift;
    return {};
}

sub get_event_handlers {
    my $self = shift;
    return { 'public' => \&url::_print_title };
}

sub get_help {
    my $self = shift;
    return {};
}

sub _print_title {
    my $self = shift;
    my $con = shift;
    my $event = shift;

    if($event->{args}[0] =~ /(https?:\/\/.*?)( |$)/) {
        my $url = $1;
        my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
        my $res = $ua->head($url);
        if($res->header('Content-Type') =~ /text\/html.*/) {
            $res = $ua->get($url);
            if($res->content =~ /<title>(.*)<\/title>/) {
                $con->privmsg($event->{to}[0], "URL: $1");
            }
        }
    }
}
1;
