package news;

use strict;
use warnings;
use utf8;

use XML::RSS;

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
        'news' => \&news::_news,
    };
}

sub get_event_handlers {
    my $self = shift;
    return {};
}

sub get_help {
    my $self = shift;

    return {};
}

sub _news {
    my $self = shift;
    my $con = shift;
    my $event = shift;
    my $cl = shift;

    my $to = $event->{type} eq 'msg' ? $event->{nick} : $event->{to}[0];
    my $rss = new XML::RSS;

    if($cl->[1]) {
        shift(@$cl);
        my $news = join(" ", @$cl);

        if(-e $self->{_config}->{file}) {
            $rss->parsefile($self->{_config}->{file});
        } else {
            $rss->channel(
                title => "/int/ Minecraft News",
                link => "$self->{_config}->{url}",
                description => "This autism is to strong for me",
                language => "en"
            );
        }

        $rss->add_item(
            title => $news,
            link => "$self->{_config}->{url}",
            author => "$event->{nick}",
            mode => 'insert',
            dc => {
                creator => "$event->{nick}"
            }
        );
        
        $rss->{output} = "2.0";
        open FILE, ">$self->{_config}->{file}";
        print FILE $rss->as_string;
        close FILE;

        $con->privmsg($to, "News: Succesful added");

    } else {
        if(-e $self->{_config}->{file}) {
            $rss->parsefile($self->{_config}->{file});
            
            my $items = $rss->{items};
            my $num = $self->{_config}->{num} > @$items ? @$items : $self->{_config}->{num};
            
            my $line = "";
            for(my $i = 0; $i < $num; $i++) {
                $line .= " $items->[$i]->{title} - $items->[$i]->{author} |";
            }
            
            $con->privmsg($to, "News:$line");
        }
    }
}
1;
