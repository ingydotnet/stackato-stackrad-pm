##
# name:      Stackato::Stackrad
# abstract:  Curses Client for Stackato
# author:    Ingy döt Net <ingy@ingy.net>
# license:   perl
# copyright: 2012

package Stackato::Stackrad;
use Mo qw'build builder default';
use Curses::UI 0;
use LWP::UserAgent 0;
use HTTP::Request 0;
use JSON::XS 0;
use YAML::XS 0;
# use XXX;
our $VERSION;
BEGIN {
    $VERSION = '0.01';
}

our $SELF;
sub PPP {
    my $self = $SELF;
    my $text = YAML::XS::Dump(@_);
    $self->cui->error($text);
    wantarray ? @_ : $_[0]
}

use constant app_name => 'Stackrad';
use constant target_key_hint => ' (set target with Ctrl+t)';
use constant default_title => app_name . target_key_hint;
use constant new_target_prompt =>
    "New target? (e.g., api.stackato.example.com)";
use constant user_agent_string =>
    app_name . "/$VERSION lwp/$LWP::UserAgent::VERSION";
use constant main_color => 'cyan';
use constant secondary_color => 'cyan';
use constant accent_color => 'red';

has targets => (default => sub{[]});

has target_index => ();
has cui => ();
has win1 => ();
has tabs => ();
has ui => (default => sub { [ 
    {
        name => 'Targets',
        contents => undef,
    },
    {
        name => 'Overview',
        contents => <<'EOT'
Memory: [ 128 MB of 256 MB ]
[----------------                  ]

1 / 2 Applications
0 / 2 Services

Applications:
[ ] tty-js [STARTED]
    Framework: node, Services: 0, Owner: as@sharpsaw.org
    [Restart] [Stop] [Launch] [Logs] [All Files] [More Info]

[ ] pairup [STARTED]
    Framework: generic, Services: 0, Owner: ingy@ingy.net
    [Restart] [Stop] [Launch] [Logs] [All Files] [More Info]

...

Provisioned Services:
[ ] filesystem  Provisioned Name: home   Bindings: 1
    [(Cannot Delete Bound Service)]
EOT
    },
    {
        name => 'Users',
        contents => <<'EOT'
[ ] ingy@activestate.com
[ ] ingy@ingy.net
[ ] as@sharpsaw.org
EOT
    },
    {
        name => 'Groups',
        contents => <<'EOT'
    Group   Users   Apps
[ ] pair    5       1
EOT
    },
    {
        name => 'App Store',
        contents => <<'EOT'
[ ] Bugzilla - perl / mysql
    A bug tracking system for individuals or groups of developers
    256MB Required - License: MPL
    (Third Party Apps for Stackato)

[ ] Currency Converter - python / redis
    Currency converter using Python bottle framework
    128MB Required - License: Unknown
    (ActiveState Stackato Sample Applications)

[ ] Drupal - php / filesystem / mysql
    A popular PHP content management system which uses mysql and
    the persistent file system
    128MB Required - License: GPLv2
    (Third Party Apps for Stackato)

[ ] ...
EOT
    },
]});


sub run {
    my $class = shift;
    my $self = $class->new();
    $SELF = $self; # XXX, PPP
    $self->setup_cui;
    $self->cui->mainloop();
}

sub setup_cui {
    my $self = shift;
    my $cui = $self->{cui} = $self->cui(
        Curses::UI->new(
            -color_support => 1,
            # -debug => 1,
        )
    );

    $cui->set_binding(sub { exit 0 }, "\cC");
    $cui->set_binding(sub { $self->prompt_for_target }, "\cT");
    $cui->set_binding(sub { $self->delete_current_target }, "\cX");
    $cui->set_binding(sub { PPP @_ }, "\c1");

    my $win1 = $self->{win1} =
        $cui->add('win1', 'Window',
            -title  => default_title,
            -bfg    => main_color,
            -border => 1,
        );
    $win1->add('help_text', 'Label',
        -y     => $win1->height - 3,
        -width => $win1->width - 2,
        -text  => 'Ctrl+n/PgUp / Ctrl+p/PgDn to switch tabs; Ctrl+C to exit',
        -textalignment => 'middle',
        -bold  => 1,
    );
    my $notebook = $win1->add('notebook', 'Notebook',
        -height => $win1->height - 3,
        -border => 1,
    );
    for my $tab (@{$self->ui}) {
        my $name = $tab->{name};
        my $id = 'tab_'.$name;
        my $page = $tab->{page} = $notebook->add_page($name);
        $tab->{tv} = $page->add(
            $id, 'TextViewer',
            -x    => 1,
            -y    => 1,
            -text => $tab->{contents},
        );
    }
    $self->update_targets_screen;
    $notebook->focus;
}

sub tab_named {
    my ($self, $name) = @_;
    for (@{$self->ui}) {
        return $_ if $name eq $_->{name};
    }
}

sub current_target {
    my $self = shift;
    return unless defined $self->target_index;
    $self->targets->[$self->target_index]
}

sub prompt_for_target {
    my $self = shift;
    my $answer = $self->cui->question(new_target_prompt);
    return unless $answer;
    push @{$self->targets}, $answer;
    $self->target_index($#{$self->targets});
    $self->update_targets_screen;
    $self->set_title
}

sub delete_current_target {
    my $self = shift;
    my $i = $self->target_index;
    return unless defined $i;
    splice @{$self->targets}, $i, 1;
    $i = undef if --$i < 0;
    $self->target_index($i);
    $self->set_title;
    $self->update_targets_screen;
}

sub update_targets_screen {
    my $self = shift;

    my $tab = $self->tab_named('Targets');
    my $out = '';
    for (0 .. $#{$self->targets}) {
        $out .= $_ == $self->target_index ? ' * ' : '   ';
        $out .= $self->targets->[$_] . "\n";
    }
    $out .= "\nPress 'Ctrl+t' to add a target.";
    $out .= "\n\nPress 'Ctrl+x' to delete current target."
        if @{$self->targets};
    $out .= "\n\nPress 'Ctrl+<target #>' to set current target."
        if @{$self->targets};
    $tab->{tv}{-text} = $out;
    $self->win1->draw(1);
}

sub set_title {
    my $self = shift;
    $self->win1->{-title} = app_name . ' - target: ' . $self->current_target;
    $self->win1->draw(1);
}

sub do_info {
    my $self = shift;
    my $text = $self->request_info;
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
    my $server = $self->current_target;
    my $request = HTTP::Request->new('GET', 'https://'.$server.$path);
    $request->header('Accept' => 'application/json');
    #? cookies?
    #? $request->header( 'Content-Type' => $p{type} )     if $p{type};
    $ua->simple_request($request)
}

1;
