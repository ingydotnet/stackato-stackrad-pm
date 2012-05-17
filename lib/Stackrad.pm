##
# name:      Stackrad
# abstract:  Curses Client for Stackato
# author:    Ingy döt Net <ingy@ingy.net>
# license:   perl
# copyright: 2012

package Stackrad;
use Mo qw'build builder default';
use Stackrad::State;
use Curses::UI 0;
use LWP::UserAgent 0;
use HTTP::Request 0;
use JSON::XS 0;
use YAML::XS 0;
use XXX;
our $VERSION = '0.10';

use constant menu_key_hint => '(Ctrl+x for menu)';

has state => (default => sub { Stackrad::State->new });
has title => (default => sub { '...no target yet... ' . menu_key_hint });
has cui => (
    default => sub {
        my $self = shift;
        $self->cui(Curses::UI->new(-color_support => 1))
    },
);
has win1 => (
    default => sub {
        my $self = shift;
        $self->cui->add('win1', 'Window',
            -border => 1,
            -y      => 1,
            -bfg    => 'green',
            -title  => $self->title,
        );
    }
);
has textviewer => ();

sub run {
    my $class = shift;
    my $self = $class->new();
    $self->setup();
    $self->dispatch;
    $self->textviewer->focus();
    $self->cui->mainloop();
}

sub setup {
    my $self = shift;
    $self->build_menu;
    my $exit_sub = sub { $self->exit_dialog };
    $self->cui->set_binding(sub {exit 0}, "\cC");
}


# - User types: stackrad
# - User gets prompted for a target
# - User goes to Overview Pane

sub dispatch {
    my $self = shift;
    if (not $self->state->welcomed) {
        $self->
    my $point = $self->state->point;
    my $method = "do_$point";
    $self->$method;
}

sub do_welcome {
    my $self = shift;
    my $text = <<EOT;
Welcome...
1
2
3
4
5
6
7
8
9
0
1
2
3
4
5
6

EOT
    my $win = $self->cui->add('mywindow', 'Window',
        -width => 50,
        -height => 10,
        -border => 1,
        -centered => 1,
        -vscrollbar => 1,
    );
    $win->add("text", "Dialog::Basic",
        -message => $text
    )
    $self->textviewer($win);
}

sub do_info {
    my $self = shift;
    my $text = $self->info;
    $self->title("Target: $self->{target} " . menu_key_hint);
    $self->textviewer($self->win1->add("text", "TextViewer", -text => $text));
}

sub prompt_for_target {
    my $self = shift;
    $self->{target} = $self->cui->question("Target?");
}

sub info {
    my $self = shift;
    my $response = $self->get('/info/');
    return "Request error: " . YAML::XS::Dump($response)
        unless $response->is_success; 
    YAML::XS::Dump(decode_json($response->content))
}

sub get {
    my ($self, $path) = @_;
    my $ua = LWP::UserAgent->new(agent => $self->agent_string);
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

sub agent_string {
    'Stackrad ... UserAgent is a TODO';
}

sub build_menu {
    my $self = shift;
    my $exit_sub = sub { $self->exit_dialog };
    my @menu = (
      {
        -label => 'Start', 
        -submenu => [
             { -label => 'Target (TODO)   ', -value => $exit_sub },
             { -label => 'Login  (TODO)   ', -value => $exit_sub },
             { -label => 'Info   (TODO)   ', -value => $exit_sub },
             { -label => 'Exit    ^Q', -value => $exit_sub }
         ],
      },
      {
        -label => 'App',
        -submenu => [
             { -label => 'apps  (TODO)   ', -value => $exit_sub },
             { -label => 'push [appname]  (TODO)   ', -value => $exit_sub },
             { -label => 'start [appname]  (TODO)   ', -value => $exit_sub },
             { -label => 'stop [appname]  (TODO)   ', -value => $exit_sub },
             { -label => 'restart [appname]  (TODO)   ', -value => $exit_sub },
             { -label => 'delete [appname...]  (TODO)   ', -value => $exit_sub },
             { -label => '- Updates  (TODO)   ', -value => $exit_sub },
             { -label => 'update [appname] [--path]  (TODO)   ', -value => $exit_sub },
             { -label => 'mem [appname] [memsize]  (TODO)   ', -value => $exit_sub },
             { -label => 'map [appname] <url>  (TODO)   ', -value => $exit_sub },
             { -label => 'unmap [appname] <url>  (TODO)   ', -value => $exit_sub },
             { -label => 'instances [appname] <num|delta>  (TODO)   ', -value => $exit_sub },
             { -label => '- Info  (TODO)   ', -value => $exit_sub },
             { -label => 'crashes [appname]  (TODO)   ', -value => $exit_sub },
             { -label => 'crashlogs [appname]  (TODO)   ', -value => $exit_sub },
             { -label => 'logs [appname] [--all]  (TODO)   ', -value => $exit_sub },
             { -label => 'files [appname] [path] [--all]  (TODO)   ', -value => $exit_sub },
             { -label => 'run [--instance N] [appname] <cmd>...  (TODO)   ', -value => $exit_sub },
             { -label => 'ssh [--instance N] [appname] [cmd...]  (TODO)   ', -value => $exit_sub },
             { -label => 'ssh api [cmd...]  (TODO)   ', -value => $exit_sub },
             { -label => 'stats [appname]  (TODO)   ', -value => $exit_sub },
             { -label => 'instances [appname]  (TODO)   ', -value => $exit_sub },
             { -label => 'open [appname]  (TODO)   ', -value => $exit_sub },
             { -label => 'open <url>  (TODO)   ', -value => $exit_sub },
             { -label => 'open api  (TODO)   ', -value => $exit_sub },
             { -label => '- Env  (TODO)   ', -value => $exit_sub },
             { -label => 'env [appname]  (TODO)   ', -value => $exit_sub },
             { -label => 'env-add [appname] <variable[=]value>  (TODO)   ', -value => $exit_sub },
             { -label => 'env-del [appname] <variable>  (TODO)   ', -value => $exit_sub },
         ],
      },
      {
        -label => 'Services',
        -submenu => [
             { -label => 'services  (TODO)   ', -value => $exit_sub },
             { -label => 'create-service <service> [--name,--bind]  (TODO)   ', -value => $exit_sub },
             { -label => 'create-service <service> <name>  (TODO)   ', -value => $exit_sub },
             { -label => 'create-service <service> <name> <app>  (TODO)   ', -value => $exit_sub },
             { -label => 'delete-service [servicename...]  (TODO)   ', -value => $exit_sub },
             { -label => 'bind-service <servicename> [appname]  (TODO)   ', -value => $exit_sub },
             { -label => 'unbind-service <servicename> [appname]  (TODO)   ', -value => $exit_sub },
             { -label => 'clone-services <src-app> <dest-app>  (TODO)   ', -value => $exit_sub },
             { -label => 'dbshell [appname] [servicename] [--print]  (TODO)   ', -value => $exit_sub },
             { -label => 'tunnel [servicename] [--port port] [--allow-http]  (TODO)   ', -value => $exit_sub },
             { -label => 'tunnel [servicename] [clientcmd] [--allow-http]  (TODO)   ', -value => $exit_sub },
         ],
      },
      {
        -label => 'Admin',
        -submenu => [
             { -label => 'user  (TODO)   ', -value => $exit_sub },
             { -label => 'passwd  (TODO)   ', -value => $exit_sub },
             { -label => 'logout  (TODO)   ', -value => $exit_sub },
             { -label => 'add-user [--email, --passwd]  (TODO)   ', -value => $exit_sub },
             { -label => 'delete-user <user>  (TODO)   ', -value => $exit_sub },
             { -label => 'users  (TODO)   ', -value => $exit_sub },
             { -label => 'admin report [destinationfile]  (TODO)   ', -value => $exit_sub },
         ],
      },
      {
        -label => 'System',
        -submenu => [
             { -label => 'runtimes  (TODO)   ', -value => $exit_sub },
             { -label => 'frameworks  (TODO)   ', -value => $exit_sub },
         ],
      },
      {
        -label => 'Misc',
        -submenu => [
             { -label => 'aliases  (TODO)   ', -value => $exit_sub },
             { -label => 'alias <alias[=]command>  (TODO)   ', -value => $exit_sub },
             { -label => 'unalias <alias>  (TODO)   ', -value => $exit_sub },
             { -label => 'targets  (TODO)   ', -value => $exit_sub },
             { -label => 'group  (TODO)   ', -value => $exit_sub },
             { -label => 'group <name>  (TODO)   ', -value => $exit_sub },
             { -label => 'group reset  (TODO)   ', -value => $exit_sub },
             { -label => 'groups create <groupname>  (TODO)   ', -value => $exit_sub },
             { -label => 'groups delete <groupname>  (TODO)   ', -value => $exit_sub },
             { -label => 'groups  (TODO)   ', -value => $exit_sub },
             { -label => 'groups add-user <groupname> <username>  (TODO)   ', -value => $exit_sub },
             { -label => 'groups delete-user <groupname> <username>  (TODO)   ', -value => $exit_sub },
             { -label => 'groups users [groupname]  (TODO)   ', -value => $exit_sub },
             { -label => 'limits …bunchastuff  (TODO)   ', -value => $exit_sub },
         ],
      },
      {
        -label => 'Help',
        -submenu => [
             { -label => 'help [command]  (TODO)   ', -value => $exit_sub },
             { -label => 'help options  (TODO)   ', -value => $exit_sub },
        ],
      },
    );

    my $menu = $self->cui->add(
            'menu','Menubar', 
            -menu => \@menu,
            -fg  => "blue",
    );

    $self->cui->set_binding(sub {$menu->focus()}, "\cX");
}

1;
