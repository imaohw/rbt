package default;

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
    return { 
        'whoami' => \&default::_whoami,
        'list' => \&default::_list,
        'help' => \&default::_help
    };
}

sub get_event_handlers {
    my $self = shift;
    return { 'endofmotd' => \&default::_join_channels };
}

sub get_help {
    my $self = shift;

    return { 
        whoami => 'Tells you who you are',
        list => 'Lists all available commands',
        help => 'Show help text'
    }
}

sub _help {
    my $self = shift;
    my $con = shift;
    my $event = shift;
    my $cl = shift;
    my $modules = shift;

    my $to = $event->{type} eq 'msg' ? $event->{nick} : $event->{to}[0];

    unless($cl->[1]) {
        $con->privmsg($to,
            "Use $self->{_config}->{callsign}list to get a list of all ".
            "available commands. Use $self->{_config}->{callsign}help COMMAND ".
            "to get help for a specific command.");
        return;
    }

    foreach(keys($modules)) {
        if($modules->{$_}->{help}->{$cl->[1]}) {
            $con->privmsg($to, $modules->{$_}->{help}->{$cl->[1]});
            return;
        }
    }

    $con->privmsg($to, "No help available");
}

sub _list {
    my $self = shift;
    my $con = shift;
    my $event = shift;
    my $cl = shift;
    my $modules = shift;

    my $to = $event->{type} eq 'msg' ? $event->{nick} : $event->{to}[0];
    
    my $line = "";
    foreach my $module(keys($modules)) {
        foreach my $cmd(keys($modules->{$module}->{commands})) {
            $line .= " $self->{_config}->{callsign}$cmd |"
        }
    }

    $con->privmsg($to, "Available Commands:$line");
}

sub _whoami {
    my $self = shift;
    my $con = shift;
    my $event = shift;
    
    my $to = $event->{type} eq 'msg' ? $event->{nick} : $event->{to}[0];

    $con->privmsg($to, "You are $event->{nick}");
}

sub _join_channels {
    my $self = shift;
    my $con = shift;
    my $event = shift;

    foreach(@{$self->{_config}->{channels}}) {
        print "joining $_\n";
        $con->join($_);
    }

    $con->mode($self->{_config}->{name}, "+$self->{_config}->{usermodes}");
}
1;
