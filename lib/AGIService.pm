package Dcrt::AGIService;

use strict;
use base 'Asterisk::FastAGI';
use Carp;

sub ivr {
  my $self = shift;

  my $class = $self->input('arg_1');
  my $config_file = $self->input('arg_2');
  load_module($class);
  my $ivr = $class->new();
  $ivr->config()->file($config_file) if $config_file;
  $ivr->run($self);
}

sub load_module {
    eval "require $_[0]";
    croak $@ if $@;
    $_[0]->import(@_[1 .. $#_]);
}



1;
__END__

