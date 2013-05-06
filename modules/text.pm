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

sub _rainbow {
    my $self = shift;
    my $con = shift;
    my $event = shift;
    my $cl = shift;

    my $c = {
        white => "\x3"."0",
        black => "\x3"."1",
        blue => "\x3"."2",
        green => "\x3"."3",
        red => "\x3"."4",
        brown => "\x3"."5",
        purple => "\x3"."6",
        orange => "\x3"."7",
        yellow => "\x3"."8",
        light_green => "\x3"."9",
        teal => "\x3"."10",
        light_cyan => "\x3"."11",
        light_blue => "\x3"."12",
        pink => "\x3"."13",
        grey => "\x3"."14",
        light_grey => "\x3"."15",
        reset => "\x3"
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
