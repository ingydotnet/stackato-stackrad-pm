##
# name:      Stackrad
# abstract:  Curses Client for Stackato
# author:    Ingy döt Net <ingy@ingy.net>
# copyright: 2012

package Stackrad;
use Curses::UI 0.9609;
use LWP::UserAgent 6.04;
use HTTP::Request 6.00;
use JSON::XS 2.32;
use YAML;
our $VERSION = '0.10';

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{cui} = Curses::UI->new(-color_support => 1);
    my $exit_sub = sub { $self->exit_dialog };
    my @menu = (
      {
        -label => 'File', 
        -submenu => [ { -label => 'Exit    ^Q', -value => $exit_sub } ],
      },
    );
    my $menu = $self->cui->add(
            'menu','Menubar', 
            -menu => \@menu,
            -fg  => "blue",
    );

    $self->{target} = $self->cui->question("Target?");

    $self->{win1} = $self->cui->add(
         'win1', 'Window',
         -border => 1,
         -y      => 1,
         -bfg    => 'green',
         -title  => $self->{target},
    );

    my $info = $self->info;

    my $texteditor = $self->{win1}->add("text", "TextEditor", -text => $info);
    $self->{texteditor} = $texteditor;

    $self->cui->set_binding(sub {$menu->focus()}, "\cX");
    $self->cui->set_binding($exit_sub, "\cQ");
    $self->cui->set_binding(sub {exit 0}, "\cC");

    $self
}

sub cui { my $self = shift; $self->{cui} } # XXX Mo me.

sub info {
    my $self = shift;
    my $response = $self->get('/info/');
    return "Request error: " . YAML::Dump($response)
        unless $response->is_success; 
    YAML::Dump(decode_json($response->content))
}

sub get {
    my ($self, $path) = @_;
    warn "Stackrad being lazy and disabling SSL cert verification!";
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
    my $ua = LWP::UserAgent->new(agent => $self->agent_string);
    my $server = $self->{target}; 
    my $request = HTTP::Request->new('GET', 'https://'.$server.$path);
    $request->header('Accept' => 'application/json');
    warn YAML::Dump($request);
    #? cookies?
    #? $request->header( 'Content-Type' => $p{type} )     if $p{type};
    $ua->simple_request($request)
}

sub agent_string {
    'Stackrad ... UserAgent is a TODO';
}

sub run {
    my $self = shift;
    $self->{texteditor}->focus();
    $self->cui->mainloop();
}

sub exit_dialog() {
    my $self = shift;
    my $return = $self->cui->dialog(
      -message   => "Do you really want to quit?",
      -title     => "Are you sure???", 
      -buttons   => ['yes', 'no'],
    );
    exit(0) if $return;
}

1;
