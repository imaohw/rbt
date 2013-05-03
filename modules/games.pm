package games;

use strict;
use warnings;
use utf8;

use Data::Dumper;

sub new {
    my $class = shift;
    my $config = shift;
    my $self = { 
        _config => $config,
        _roulette => 0
    };
    bless($self, $class);
    return $self;
}

sub get_commands {
    my $self = shift;
    return { 'roulette' => \&games::_roulette };
}

sub get_event_handlers {
    my $self = shift;
    return {};
}

sub _roulette {
    my $self = shift;
    my $con = shift;
    my $event = shift;
    my $cl = shift;

    if($self->{_roulette} == 0) {
        $con->me($event->{to}[0], "reloads and spins the chambers.");
    }
    
    unless(int(rand(6-$self->{_roulette}))) {
        $con->privmsg($event->{to}[0], "BOOM! Headshot!");
        $con->mode($event->{to}[0], '+b', $event->{nick});
        $con->schedule($self->{_config}->{roulette}->{bantime}, sub { $con->mode($event->{to}[0], '-b', $event->{nick})} );
        $con->kick($event->{to}[0], $event->{nick});
        $self->{_roulette} = 0;
    } else {
        $con->privmsg($event->{to}[0], "Click");
        $self->{_roulette}++;
    }    
}
1;
