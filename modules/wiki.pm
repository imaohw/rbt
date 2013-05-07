package wiki;

use strict;
use warnings;
use utf8;

use LWP::UserAgent;
use XML::RSSLite;

sub new {
    my $class = shift;
    my $config = shift;
    my $self = { _config => $config };
    bless($self, $class);
    return $self;
}

sub get_commands {
    my $self = shift;
    return { 'wiki' => \&wiki::_wiki };
}

sub get_event_handlers {
    my $self = shift;
    return {};
}

sub get_help {
    my $self = shift;
    return {};
}

sub _wiki {
    my $self = shift;
    my $con = shift;
    my $event = shift;
    
    my $to = $event->{type} eq 'msg' ? $event->{nick} : $event->{to}[0];

    my $feed = {};
    my $res = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 })->get("$self->{_config}->{url}/feed.php?type=rss2&num=$self->{_config}->{amount}&mode=recent&linkto=current");

    if($res->header('Client-Warning') && $res->header('Client-Warning') eq 'Internal response') {
        return;
    }
    my $cont = $res->content;
    parseRSS($feed, \$cont);
    
    my $line = "";
    foreach(@{$feed->{item}}) {
        $line .= " $_->{title} $_->{link} |"
    }

    $con->privmsg($to, "Recent changes:$line");
}
1;
