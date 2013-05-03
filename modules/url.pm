package url;

use strict;
use warnings;
use utf8;

use LWP::Simple;

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

sub _print_title {
    my $self = shift;
    my $con = shift;
    my $event = shift;

    if($event->{args}[0] =~ /(https?:\/\/.*?)( |$)/) {
        my $url = $1;
        
        my @head = head($url);
        if(@head && $head[0] =~ /text\/html.*/) {
            my $page = get($url);
            if($page && $page =~ /<title>(.*)<\/title>/) {
                $con->privmsg($event->{to}[0], "URL: $1");
            }
        }
    }
}
1;
