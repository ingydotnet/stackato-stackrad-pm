##
# name:      Stackrad
# abstract:  Curses Client for Stackato
# author:    Ingy döt Net <ingy@ingy.net>
# copyright: 2012

package Stackrad;
use Mo qw'build builder';
use Curses::UI 0.9609;
use LWP::UserAgent 6.04;
use HTTP::Request 6.00;
use JSON::XS 2.32;
use YAML;
our $VERSION = '0.10';

has 'cui';
has 'texteditor';

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->cui(Curses::UI->new(-color_support => 1));

    $self->{target} = $self->cui->question("Target?");
    
    my $title = "Target: $self->{target} (Ctrl+x for menu)";

    $self->{win1} = $self->cui->add(
         'win1', 'Window',
         -border => 1,
         -y      => 1,
         -bfg    => 'green',
         -title  => $title,
    );

    my $info = $self->info;
    $self->texteditor($self->{win1}->add("text", "TextEditor", -text => $info));

    $self->build_menu;

    my $exit_sub = sub { $self->exit_dialog };
    $self->cui->set_binding($exit_sub, "\cQ");
    $self->cui->set_binding(sub {exit 0}, "\cC");

    $self
}

sub info {
    my $self = shift;
    my $response = $self->get('/info/');
    return "Request error: " . YAML::Dump($response)
        unless $response->is_success; 
    YAML::Dump(decode_json($response->content))
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

sub run {
    my $self = shift;
    $self->texteditor->focus();
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
