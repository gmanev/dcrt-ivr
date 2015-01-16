package Dcrt::IVR::RegisterCode;

use strict;
use AppConfig qw(:argcount);
use LWP::UserAgent;

sub new {
  my $class = shift;
  my $self = bless ({}, ref($class) || $class);

  my $config = AppConfig->new();
  
  $config->define("register_uri", {
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
	  DEFAULT  => 5000,
  });

  $config->define("register_maxdigits", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => 10,
  });

  $config->define("register_maxerrors", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => 2,
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

  $self->{config} = $config;

  return ($self);
}

# get module config
sub config {
  my $self = shift;
  return $self->{config};
}

# entry point
sub run {
  my $self = shift;
  my $service = shift;

  my $config = $self->config;
  my $agi = $service->agi;

  my $callid = $service->input('uniqueid');
  my $callerid = $service->input('callerid');

  $agi->answer();

  my $errors = 0; # consecutive errors counter
  my $code = '';  #
  # check for valid callerid
  if ($callerid =~ /^\d+$/) {
    # play greeting
    $code = $agi->get_data(
      $config->register_audio_start,
      $config->register_timeout,
      $config->register_maxdigits
    ) || '';
  }
  else {
    $errors = $config->register_maxerrors;
    $service->log(1, "%s|REGISTER_BLOCK|%s", $callid, $callerid);
  }

  # $code == -1 when caller hangup
  while ($code ne '-1' && $errors < $config->register_maxerrors) {
    my $status = '';
    my $is_success = 0;
    if ($code ne '') {
      # call the webservice
      my %options = $config->varlist("^lwp_", 1);
      my $ua = LWP::UserAgent->new(%options);
      my $t_start = time();
      my $response = $ua->get( $config->register_uri."/$callerid/$code" );
      my $ttime = time() - $t_start;
      $status = $response->status_line;
      # check response
      if ($response->is_success) {
        my $content = $response->decoded_content;
        $is_success = $content eq '0';
        $status .= " [$content]";
      }
      else {
        $status .= " [$ttime]";
      }
    }

    if ($is_success) {
      $service->log(1, "%s|REGISTER_PASS|%s", $callid, $status);
      # reset error counter
      $errors = 0;
      # play confirmation
      $code = $agi->get_data(
        $config->register_audio_pass,
        $config->register_timeout,
        $config->register_maxdigits
      ) || '';
    }
    else {
      $service->log(1, "%s|REGISTER_FAIL|%s", $callid, $status);
      if (++$errors < $config->register_maxerrors) {
        # try again
        $code = $agi->get_data(
          $config->register_audio_fail,
          $config->register_timeout,
          $config->register_maxdigits
        ) || '';
      }
    }
  } # while
  
  if ($errors && $code ne '-1' && $config->register_audio_helpdesk) {
    $service->log(1, "%s|REGISTER_HELPDESK|%s", $callid, $code);
    # connect to helpdesk
    $agi->stream_file( $config->register_audio_helpdesk );
    $agi->set_context( $config->helpdesk_context );
    $agi->set_extension( $config->helpdesk_extension );
    $agi->set_priority( $config->helpdesk_priority );
  }

  return 0;
}

1;
