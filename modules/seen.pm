package seen;

use strict;
use warnings;
use utf8;

use File::Slurp;
use JSON;

sub new {
    my $class = shift;
    my $config = shift;
    my $self = { 
        _config => $config,
        _file => $config->{database},
        _data => {}
    };
    bless($self, $class);
    $self->_read_database();
    return $self;
}

sub get_commands {
    my $self = shift;
    return { 'seen' => \&seen::_seen };
}

sub get_event_handlers {
    my $self = shift;
    return { 'public' => \&seen::_update_database };
}

sub _read_database {
    my $self = shift;
    
    if(-e $self->{_file}) {
        my $data = read_file($self->{_file});
        $self->{_data} = decode_json($data);
    }
}

sub _update_database {
    my $self = shift;
    my $con = shift;
    my $event = shift;

    $self->{_data}->{$event->{nick}}->{time} = time();
    $self->{_data}->{$event->{nick}}->{said} = ${$event->{args}}[0];

    open FILE, ">$self->{_file}";
        print FILE encode_json($self->{_data});
    close FILE;
}

sub _seen {
    my $self = shift;
    my $con = shift;
    my $event = shift;
    my $cl = shift;

    unless($cl->[1]) {
        return;
    }

    my $time = time();
    my $to = $event->{type} eq 'msg' ? $event->{nick} : $event->{to}[0];
    my $line = "Seen: ";

    if($self->{_data}->{$cl->[1]}) {
        my $time = $self->_sec2human(time() - $self->{_data}->{$cl->[1]}->{time});
        $line .= "$cl->[1] was last seen $time ago: $self->{_data}->{$cl->[1]}->{said}";
    } else {
        $line .= "I don't know this humanoid";
    }

    $con->privmsg($to, $line);
}

sub _sec2human {
    my $self = shift;
    my $sec = shift;

    my $d = int($sec/(24*60*60));
    my $h = ($sec/(60*60))%24;
    my $m = ($sec/60)%60;
    my $s = $sec%60;

    my $t = "";
    $t .= "$d days " if($d);
    $t .= "$h hours " if($h);
    $t .= "$m minutes " if($m);
    $t .= "$s seconds";

    return $t;
}
1;
