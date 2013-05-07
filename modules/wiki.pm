package wiki;

use strict;
use warnings;
use utf8;

use LWP::Simple;
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
    my $page = get("$self->{_config}->{url}/feed.php?type=rss2&num=$self->{_config}->{amount}&mode=recent&linkto=current") || print $!;

    parseRSS($feed, \$page);
    
    my $line = "";
    foreach(@{$feed->{item}}) {
        $line .= " $_->{title} $_->{link} |"
    }

    $con->privmsg($to, "Recent changes:$line");
}
1;
