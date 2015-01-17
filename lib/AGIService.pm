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
  $self->log_info('MODULE_START', $class);
  $ivr->run($self);
  $self->log_info('MODULE_STOP', $class);
}

sub load_module {
    eval "require $_[0]";
    croak $@ if $@;
    $_[0]->import(@_[1 .. $#_]);
}

sub log_info {
  my ($self, $action, $data) = @_;
  $self->log(1,$self->input('uniqueid').'|'.$action.'|'.$data);
}

1;
__END__

