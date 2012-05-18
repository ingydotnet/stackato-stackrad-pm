##
# name:      Stackrad
# abstract:  Curses Client for Stackato
# author:    Ingy döt Net <ingy@ingy.net>
# license:   perl
# copyright: 2012

package Stackrad;
use Mo qw'build builder default';
use Stackrad::State;
use Stackrad::Menu;
use Curses::UI 0;
use LWP::UserAgent 0;
use HTTP::Request 0;
use JSON::XS 0;
use YAML::XS 0;
use XXX;
our $VERSION = '0.10';
use constant VERSION => '0.10'; # XXX dedup (is there some $VERSION parser?)

use constant app_name => 'Stackrad';
use constant target_key_hint => ' (set target with Ctrl+t)';
use constant default_title => app_name . target_key_hint;
use constant new_target_prompt =>
    "New target? (e.g., api.stackato.example.com)";
use constant user_agent_string =>
    "Stackrad/" . VERSION . " lwp/$LWP::UserAgent::VERSION";
use constant main_color => 'blue';
use constant secondary_color => 'red';


has cui => ();
has win1 => ();
has textviewers => (default => sub { {} }); # XXX can it work without sub {}?

sub run {
    my $class = shift;
    my $self = $class->new();
    $self->setup_cui();
    $self->cui->mainloop();
}

sub setup_cui {
    my $self = shift;
    my $cui = $self->{cui} =
        $self->cui(Curses::UI->new(-color_support => 1));
    my $win1 = $self->{win1} =
        $self->cui->add('win1', 'Window',
            -title  => default_title,
            -bfg    => main_color,
            -border => 1,
            -y      => 1,
        );
    my $menu = $self->cui->add(
        'menu','Menubar', 
        -menu => [
            {
            -label   => 'View',
            -submenu => [
            {
                -label => 'Targets',
                -value => sub { $_[0]->switch_to('targets') },
            },
            {
                -label => 'Overview',
                -value => sub { $_[0]->switch_to('overview') },
            },
            {
                -label => 'Users',
                -value => sub { $_[0]->switch_to('users') },
            },
            {
                -label => 'Groups',
                -value => sub { $_[0]->switch_to('groups') },
            },
        ]}
        ],
        # Stackrad::Menu->new->menu,
        -fg  => "blue",
    );

    $self->cui->set_binding(sub {$menu->focus()}, "\cX");
    $self->cui->set_binding(sub {exit 0}, "\cC");
}


# - User types: stackrad
# - User gets prompted for a target
# - User goes to Overview Pane

sub prompt_for_target {
    my $self = shift;
    $self->{target} = $self->cui->question(new_target_prompt);
}

sub do_info {
    my $self = shift;
    my $text = $self->request_info;
    $self->title("Target: $self->{target}" . target_key_hint);
    $self->win1->add("text", "TextViewer", -text => $text);
}

sub request_info {
    my $self = shift;
    my $response = $self->get('/info/');
    return "Request error: " . YAML::XS::Dump($response)
        unless $response->is_success; 
    YAML::XS::Dump(decode_json($response->content))
}

sub get {
    my ($self, $path) = @_;
    my $ua = LWP::UserAgent->new(agent => user_agent_string);
    warn "Stackrad being lazy and disabling SSL cert verification!";
    $ua->ssl_opts(
        verify_hostname => 0,
        #? SSL_ca_path => '/app/fs/pair/certcert/stackato.ddns.us.pem',
    );
    my $server = $self->{target}; 
    my $request = HTTP::Request->new('GET', 'https://'.$server.$path);
    $request->header('Accept' => 'application/json');
    #? cookies?
    #? $request->header( 'Content-Type' => $p{type} )     if $p{type};
    $ua->simple_request($request)
}

1;
