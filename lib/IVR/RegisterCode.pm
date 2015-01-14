package Dcrt::IVR::RegisterCode;

use strict;
use AppConfig qw(:argcount);

sub new {
  my $class = shift;
  my $self = bless ({}, ref($class) || $class);

  my $config_file = shift;
  my $config = AppConfig->new();
  
  $config->define("register_endpoint", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => '',
  });

  $config->define("register_audio_start", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => '',
  });

  $config->define("register_audio_pass", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => '',
  });

  $config->define("register_audio_fail", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => '',
  });

  $config->define("register_audio_helpdesk", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => '',
  });

  $config->define("register_timeout", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => 10000,
  });

  $config->define("register_maxdigits", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => 10,
  });

  $config->define("lwp_timeout", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => 5,
  });

  $config->define("helpdesk_context", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => 'from-internal',
  });

  $config->define("helpdesk_extension", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => '',
  });

  $config->define("helpdesk_priority", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => '1',
  });

  $config->file($config_file) if $config_file;

  $self->{config} = $config;
  return ($self);
}

sub run {
  my $self = shift;
  my $service = shift;

  my $config = $self->{config};
  my $agi = $service->agi;
  my $connect_helpdesk = 0;
  my $registered = 0;

  $agi->answer();

  # first attempt
  my $code = $agi->get_data(
    $config->register_audio_start,
    $config->register_timeout,
    $config->register_maxdigits
  );

  while (!$connect_helpdesk && !$registered) {
    if ($code eq '-1') {
      # error
      $connect_helpdesk = 1;
    }
    elsif ($code eq '') {
      # timeout
      $connect_helpdesk = 1;
    }
    else {
      # call the web service
    }
  }

  
  $service->log(1, $code);

  if ($connect_helpdesk) {
    $agi->stream_file( $config->register_audio_helpdesk );
    # connect to helpdesk
    $agi->set_context( $config->helpdesk_context );
    $agi->set_extension( $config->helpdesk_extension );
    $agi->set_priority( $config->helpdesk_priority );
  }

  return 0;
}



1;
