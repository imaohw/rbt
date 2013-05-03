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
    return { 'whoami' => \&default::_whoami };
}

sub get_event_handlers {
    my $self = shift;
    return { 'endofmotd' => \&default::_join_channels };
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
}
1;
