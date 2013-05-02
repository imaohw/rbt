#!/usr/bin/env perl 

package rbt;

use strict;
use warnings;
use utf8;

use File::Slurp;
use JSON;
use Net::IRC;

sub new {
    my $class = shift;

    my $config_file = shift;

    my $self = { 
        _config => {},
        _modules => {}
    };
    bless($self, $class);

    $self->_load_config($config_file);

    return $self;
}

sub load_modules {
    my $self = shift;
    my $module_dir = shift;

    unless(-e $module_dir) {
        print("Module dir not found\n");
        exit 1;
    }

    foreach(keys($self->{_config}->{plugins})) {
        require("$module_dir/$_.pm");
        my $module = $_->new($self->{_config}->{plugins}->{$_});
        
        $self->{_modules}->{$_} = {
            instance => $module,
            events => $module->get_event_handlers,
            commands => $module->get_commands
        };
        
        print "Module loaded: $_\n";
    }
}

sub run {
    my $self = shift;

    my $irc = Net::IRC->new();
    my $con = $irc->newconn( Nick => $self->{_config}->{bot}->{name},
                             Server => $self->{_config}->{server}->{hostname},
                             Port => $self->{_config}->{server}->{port},
                             Username => $self->{_config}->{bot}->{username},
                             Ircname => $self->{_config}->{bot}->{realname},
                             SSL => $self->{_config}->{server}->{ssl}
                            );
    #closure magic
    my $evth = sub { $self->_handle_event(@_); };
    my $pubh = sub { $self->_public_msg(@_); };
    $con->add_global_handler('endofmotd', $evth);
    $con->add_global_handler('public', $pubh);
    $irc->start;
}

sub _handle_event {
    my ($self, $con, $event) = @_;
    
    my $event_name = $event->{type};

    foreach(keys($self->{_modules})) {
        if($self->{_modules}->{$_}->{events}->{$event_name}) {
            $self->{_modules}->{$_}->{events}->{$event_name}->($self->{_modules}->{$_}->{instance}, ($con, $event));
        }
    }
}

sub _public_msg {
    my ($self, $con, $event) = @_;
 
    if($self->{_config}->{bot}->{callsign} eq substr(@{$event->{args}}[0],0,1)) {
        my $line = substr(${$event->{args}}[0],1);
        my @cl = split(/ /, $line);

        if($cl[0]) {
            foreach(keys($self->{_modules})) {
                if($self->{_modules}->{$_}->{commands}->{$cl[0]}) {
                    $self->{_modules}->{$_}->{commands}->{$cl[0]}->($self->{_modules}->{$_}->{instance}, ($con, $event));
                }
            }
        }
    }
}

sub _load_config {
    my $self = shift;
    my $config_file = shift;

    unless(-e $config_file) {
        $self->_write_default_config($config_file);
        exit 0;
    }

    my $conf = read_file($config_file);
    $self->{_config} = decode_json($conf);
}

sub _write_default_config {
    my $self = shift;
    my $config_file = shift;

    my $conf = {
        bot => {
            name => 'rbt',
            username => 'rbt',
            realname => 'rbt',
            callsign => '!'
        },
        server => {
            hostname => "irc.host",
            port => "6667",
            ssl => "0"
        },
        plugins => {
            default => { 
                channels => [
                    '#test'
                ]
            },
            wiki => {
                url => 'http://dokuwiku.example',
                amount => '5'
            }
        }
    };
    
    my $json = JSON->new->allow_nonref;
    open FILE, ">$config_file" || die $!;
        print FILE $json->pretty->encode($conf);
    close FILE;
}

package main;
my $bot = rbt->new("conf.json");
$bot->load_modules("modules");
$bot->run;

