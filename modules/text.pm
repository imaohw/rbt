package text;

use strict;
use warnings;
use utf8;

sub new {
    my $class = shift;
    my $config = shift;
    my $self = { _config => $config };
    bless($self, $class);
    return $self;
}

sub get_commands {
    my $self = shift;
    return { 'rainbow' => \&text::_rainbow };
}

sub get_event_handlers {
    my $self = shift;
    return { };
}

sub get_help {
    my $self = shift;
    return {};
}

sub _rainbow {
    my $self = shift;
    my $con = shift;
    my $event = shift;
    my $cl = shift;

    my $c = {
        white => "\x0300",
        black => "\x0301",
        blue => "\x0302",
        green => "\x0303",
        red => "\x0304",
        brown => "\x0305",
        purple => "\x0306",
        orange => "\x0307",
        yellow => "\x0308",
        light_green => "\x0309",
        teal => "\x0310",
        light_cyan => "\x0311",
        light_blue => "\x0312",
        pink => "\x0313",
        grey => "\x0314",
        light_grey => "\x0315",
        reset => "\x03"
    };
    
    unless($cl->[1]) {
        return;
    }

    my $to = $event->{type} eq 'msg' ? $event->{nick} : $event->{to}[0];

    shift(@$cl);
    my @chars = split(//, join(" ", @$cl));
    my @colors = ('red', 'orange', 'yellow', 'light_green', 'green','light_cyan' ,'teal', 'light_blue', 'blue', 'purple');

    my $line = "";
    foreach (@chars) {
        my $color = shift(@colors);
        $line .= "$c->{$color}$_$c->{reset}";
        push(@colors, $color);
    }

    $con->privmsg($to, "$line");
}

1;
