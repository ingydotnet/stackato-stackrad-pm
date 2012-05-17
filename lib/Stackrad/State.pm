##
# name:      Stackrad::State
# abstract:  Stackrad State Object
# author:    Ingy döt Net <ingy@ingy.net>
# license:   perl
# copyright: 2012

package Stackrad::State;
use Mo qw'build builder default';
use YAML::XS 0;

use constant stackrad_dir => "$ENV{HOME}/.stackrad";
use constant state_file => stackrad_dir . "/state";

has point => (default => sub {'welcome'});

-d stackrad_dir or
    mkdir stackrad_dir or die "Couldn't mkdir " . stackrad_dir . ": $!";

sub BUILD {
    my $self = shift;
    $self->load_state;
}

sub DESTROY {
    my $self = shift;
    # Not sure about this...
    # $self->save_state;
}

sub load_state {
    my $self = shift;
    if (-f state_file) {
        %$self = %{(YAML::XS::Load(state_file))};
    }
}

sub save_state {
    my $self = shift;
    %$self = %{(YAML::XS::Dump(state_file, $self))};
}

1;
