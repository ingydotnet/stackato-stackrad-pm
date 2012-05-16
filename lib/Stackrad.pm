##
# name:      Stackrad
# abstract:  Curses Client for Stackato
# author:    Ingy döt Net <ingy@ingy.net>
# copyright: 2012

package Stackrad;
use Curses::UI 0.9609;
our $VERSION = '0.10';

our $cui; # XXX global hack for exit_dialog()
sub new {
    my $class = shift;
    my $self = {};
    $self->{cui} = Curses::UI->new(-color_support => 1);
    $cui = $self->{cui};
    my @menu = (
      {
        -label => 'File', 
        -submenu => [ { -label => 'Exit      ^Q', -value => \&exit_dialog  } ]
      },
    );
    my $menu = $cui->add(
            'menu','Menubar', 
            -menu => \@menu,
            -fg  => "blue",
    );

    my $win1 = $cui->add(
         'win1', 'Window',
         -border => 1,
         -y    => 1,
         -bfg  => 'red',
    );

    my $texteditor = $win1->add(
        "text", "TextEditor", -text => "Here is some text\n" . "And some more");
    $self->{texteditor} = $texteditor;

    $cui->set_binding(sub {$menu->focus()}, "\cX");
    $cui->set_binding(\&exit_dialog , "\cQ");

    bless $self, $class;
}

sub run {
    my $self = shift;
    warn "hiho\n";
    $self->{texteditor}->focus();
    $self->{cui}->mainloop();
}

sub exit_dialog()
{
    my $return = $cui->dialog(
      -message   => "Do you really want to quit?",
      -title     => "Are you sure???", 
      -buttons   => ['yes', 'no'],
    );
    exit(0) if $return;
}

1;
