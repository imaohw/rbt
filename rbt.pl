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
            commands => $module->get_commands,
            help => $module->get_help
        };
        
        print "Module loaded: $_\n";
    }
}

sub run {
    my $self = shift;

    my $irc = Net::IRC->new();
    my $con = $irc->newconn( Nick => $self->{_config}->{plugins}->{default}->{name},
                             Server => $self->{_config}->{server}->{hostname},
                             Port => $self->{_config}->{server}->{port},
                             Username => $self->{_config}->{server}->{username},
                             Ircname => $self->{_config}->{server}->{realname},
                             SSL => $self->{_config}->{server}->{ssl}
                            );
    #closure magic
    my $evth = sub { $self->_handle_event(@_); };
    my $pubh = sub { $self->_msg(@_); };
    $con->add_global_handler('endofmotd', $evth);
    $con->add_global_handler('join', $evth);
    $con->add_global_handler('part', $evth);
    $con->add_global_handler('quit', $evth);
    $con->add_global_handler('namreply', $evth);
    $con->add_global_handler('public', $pubh);
    $con->add_global_handler('msg', $pubh);
    $irc->start;
}

sub _handle_event {
    my ($self, $con, $event) = @_;
    
    my $event_name = $event->{type};

    foreach(keys($self->{_modules})) {
        if($self->{_modules}->{$_}->{events}->{$event_name}) {
            $self->{_modules}->{$_}->{events}->{$event_name}->($self->{_modules}->{$_}->{instance}, ($con, $event, $self->{_modules}));
        }
    }
}

sub _msg {
    my ($self, $con, $event) = @_;
    
    if(($self->{_config}->{plugins}->{default}->{callsign} eq substr(@{$event->{args}}[0],0,1)) || $event->{type} eq 'msg') {
        my $cmd = ${$event->{args}}[0];
        $cmd =~ s/^$self->{_config}->{plugins}->{default}->{callsign}//;
        my @cl = split(/ /, $cmd);

        if($cl[0]) {
            foreach(keys($self->{_modules})) {
                if($self->{_modules}->{$_}->{commands}->{$cl[0]}) {
                    $self->{_modules}->{$_}->{commands}->{$cl[0]}->($self->{_modules}->{$_}->{instance}, ($con, $event, \@cl, $self->{_modules}));
                }
            }
        }
    } else {
        $self->_handle_event($con, $event);
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
        server => {
            hostname => "irc.example.com",
            port => "6667",
            ssl => "0",
            username => 'rbt',
            realname => 'rbt',

        },
        plugins => {
            default => { 
                channels => [
                    '#test'
                ],
                name => 'rbt',
                callsign => '!',
                usermodes => 'B'
            },
            wiki => {
                url => 'http://dokuwiki.example.com',
                amount => '5'
            },
            url => {},
            weather => {},
            games => {
                roulette => {
                    bantime => 300
                }
            },
            web => {},
            admin => {
                NICKNAME => 'PASSWORT'
            },
            flyspray => {
                url => "http://flyspray.example.com",
                num => "5",
                project => "2"
            },
            seen => {
                database => "seen.json"
            }
        }
    };
    
    my $json = JSON->new->allow_nonref;
    open FILE, ">$config_file" || die $!;
        print FILE $json->pretty->encode($conf);
    close FILE;
}

package main;

use strict;
use warnings;

use Getopt::Long;

sub print_help {
    print "$0 [-c configfile] [-m module_dir]\n";
    print "  OPTIONS\n";
    print "    -c,  --config        Config file(Default: conf.json)\n";
    print "    -m,  --modules       Module directory(Default: modules)\n";
    print "    -h,  --help          Print this help\n";
}


my $opt = {
    config => 'conf.json',
    modules => 'modules'
};

exit 1 if !GetOptions($opt,
              'config|c=s',
              'modules|m=s',
              'help|h'
          );

if($opt->{help}) {
    print_help();
    exit 0;
}

my $bot = rbt->new($opt->{config});
$bot->load_modules($opt->{modules});
$bot->run;

