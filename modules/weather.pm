package weather;

use strict;
use warnings;
use utf8;

use JSON;
use LWP::UserAgent;

sub new {
    my $class = shift;
    my $config = shift;
    my $self = { _config => $config };
    bless($self, $class);
    return $self;
}

sub get_commands {
    my $self = shift;
    return { 'weather' => \&weather::_weather };
}

sub get_event_handlers {
    my $self = shift;
    return {};
}

sub get_help {
    my $self = shift;
    return {};
}

sub _weather {
    my $self = shift;
    my $con = shift;
    my $event = shift;
    my $cl = shift;

    my $to = $event->{type} eq 'msg' ? $event->{nick} : $event->{to}[0];

    unless($cl->[1]) {
        $con->privmsg($to, "I need a city you stupid human");
        return;
    }

    my $query_url = "http://autocomplete.wunderground.com/aq?query=";
    my $weather_url = "http://api.wunderground.com/api/19dfaf9fb009b00d/conditions";

    my $res = LWP::UserAgent->new()->get("http://autocomplete.wunderground.com/aq?query=${$cl}[1]");
    
    unless($res->header('Client-Warning') && $res->header('Client-Warning') eq 'Internal response') {
        my $data = decode_json($res->content);

        unless(${$data->{RESULTS}}[0]->{l}) {
            return;
        }

        $res = LWP::UserAgent->new()->get("http://api.wunderground.com/api/19dfaf9fb009b00d/conditions${$data->{RESULTS}}[0]->{l}.json");
        unless($res->header('Client-Warning') && $res->header('Client-Warning') eq 'Internal response') {
            $data = decode_json($res->content);

            if($data && $data->{response}->{features}->{conditions}) {
                my $line = "Weather: $data->{current_observation}->{display_location}->{full} | ";
                $line .= "$data->{current_observation}->{temperature_string} - $data->{current_observation}->{weather} | ";
                $line .= "Wind: $data->{current_observation}->{wind_kph}kph $data->{current_observation}->{wind_dir} | ";
                $line .= "Humidity: $data->{current_observation}->{relative_humidity} | ";
                $line .= "Pressure: $data->{current_observation}->{pressure_mb}mbar";

                $con->privmsg($to, $line);
            }
        }
    }
}
1;
