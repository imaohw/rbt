package admin;

use strict;
use warnings;
use utf8;

sub new {
    my $class = shift;
    my $config = shift;
    my $self = { 
        _config => $config,
        _identified => {}
    };
    bless($self, $class);
    return $self;
}

sub get_commands {
    my $self = shift;
    return { 
        'identify' => \&admin::_identify,
        'join' => \&admin::_join,
        'part' => \&admin::_part
    };
}

sub get_event_handlers {
    my $self = shift;
    return {};
}

sub _join {
    my $self = shift;
    my $con = shift;
    my $event = shift;
    my $cl = shift;

    unless($cl->[1] && $self->{_identified}->{$event->{from}}) {
        return;
    }

    $con->join($cl->[1]);
}

sub _part {
    my $self = shift;
    my $con = shift;
    my $event = shift;
    my $cl = shift;

    unless($cl->[1] && $self->{_identified}->{$event->{from}}) {
        return;
    }

    $con->part($cl->[1]);
}

sub _identify {
    my $self = shift;
    my $con = shift;
    my $event = shift;
    my $cl = shift;

    if($event->{type} ne 'msg') {
        return;
    }

    my $to = $event->{nick};

    unless($cl->[1]) {
        $con->privmsg($to, "Usage: identify PASSWORD");
        
        return;
    }

    if($self->{_identified}->{$event->{from}}) {
        $con->privmsg($to, "Success");
        
        return;
    }

    if($self->{_config}->{$to} && $self->{_config}->{$to} eq $cl->[1]) {
        $self->{_identified}->{$event->{from}} = 1;
        $con->privmsg($to, "Success");

        return;
    }

    $con->privmsg($event->{to}[0], "Unknown user or wrong password");
}

sub _join_channels {
    my $self = shift;
    my $con = shift;
    my $event = shift;

    foreach(@{$self->{_config}->{channels}}) {
        print "joining $_\n";
        $con->join($_);
    }
}
1;
