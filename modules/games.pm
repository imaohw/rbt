package games;

use strict;
use warnings;
use utf8;

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
    return { 
        'roulette' => \&games::_roulette,
        '8ball' => \&games::_eightball,
        'jn' => \&games::_jn
    };
}

sub get_event_handlers {
    my $self = shift;
    return {};
}

sub _jn {
    my $self = shift;
    my $con = shift;
    my $event = shift;
    my $cl = shift;

    unless($cl->[1]) {
        return;
    }

    my $to = $event->{type} eq 'msg' ? $event->{nick} : $event->{to}[0];
    my $answer = int(rand(2)) ? "Yes" : "No";

    $con->privmsg($to, $answer);
}

sub _eightball {
    my $self = shift;
    my $con = shift;
    my $event = shift;
    my $cl = shift;

    my @answers = (
        "Signs point to yes",
        "Yes",
        "Without a doubt",
        "As I see it, yes",
        "Most likely",
        "You may rely on it",
        "Yes definitely",
        "It is decidedly so",
        "Outlook good",
        "It is certain",
        "My sources say no",
        "Very doubtful",
        "Don't count on it",
        "Outlook not so good",
        "My reply is no",
        "Reply hazy, try again",
        "Concentrate and ask again",
        "Better not tell you now",
        "Cannot predict now",
        "Ask again later"
    );
    
    my $to = $event->{type} eq 'msg' ? $event->{nick} : $event->{to}[0];

    if($cl->[1]) {
        $con->privmsg($to, $answers[int(rand(@answers))]);
    }
}

sub _roulette {
    my $self = shift;
    my $con = shift;
    my $event = shift;
    my $cl = shift;

    if($event->{type} eq 'msg') {
        return;
    }

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
