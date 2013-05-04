package flyspray;

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
    return { 
        'bugs' => \&flyspray::_bugs,
        'flyspray' => \&flyspray::_bugs
    };
}

sub get_event_handlers {
    my $self = shift;
    return {};
}

sub _bugs {
    my $self = shift;
    my $con = shift;
    my $event = shift;
    my $cl = shift;
    
    my $to = $event->{type} eq 'msg' ? $event->{nick} : $event->{to}[0];

    if($cl->[1] && $cl->[1] =~ /(\d+)/) {
        my $res = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 })->get("$self->{_config}->{url}/index.php?do=details&task_id=$1");
        if($res->header('Client-Warning') && $res->header('Client-Warning') eq 'Internal response') {
            return;
        }
        
        my $cont = $res->content;
        $cont =~ s/\R//g;
        $cont =~ s/\t//g;

        if($cont =~ /<div id="taskdetailstext">(.*?)<\/div>/) {
            my $text = $1;
            $text =~ s/<.*?>/ /g;
            $con->privmsg($to, "Task: $text");
        }

    } else {
        my $feed = {};
        my $res = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 })->get("$self->{_config}->{url}/feed.php?num=$self->{_config}->{num}&feed_type=rss2&project=$self->{_config}->{project}") || print $!;
    
        if($res->header('Client-Warning') && $res->header('Client-Warning') eq 'Internal response') {
            return;
        }
        my $cont = $res->content;
        $cont =~ s/<!\[CDATA\[//g;
        $cont =~ s/\]\]>//g;
        parseRSS($feed, \$cont);

        my $line = "";
        foreach(@{$feed->{item}}) {
            my $link = $_->{link};
            $link =~ s/$self->{_config}->{url}\/index\.php\?do=details&amp;task_id=(\d+)/$self->{_config}->{url}\/task\/$1/;
            $line .= " $_->{title} $link |";
        }

        $con->privmsg($to, "Recent tasks:$line");
    }
}
1;
