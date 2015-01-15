package Dcrt::IVR::RegisterCode;

use strict;
use AppConfig qw(:argcount);
use HTTP::Request;
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

  $self->{config} = $config;

  return ($self);
}

# get module configuration
sub config {
  my $self = shift;
  return $self->{config};
}

sub run {
  my $self = shift;
  my $service = shift;

  my $config = $self->config;
  my $agi = $service->agi;

  my $callid = $service->input('uniqueid');
  my $callerid = $service->input('callerid');

  $agi->answer();

  my $code = '-2'; # invalid callerid
  if ($callerid =~ /^\d+$/) {
    # first attempt
    $code = $agi->get_data(
      $config->register_audio_start,
      $config->register_timeout,
      $config->register_maxdigits
    );
  }
  else {
    $service->log(1, "%s|REGISTER_BLOCK|%s", $callid, $callerid);
  }

  my $errors = 0; # error counter
  while ($code ne '-2' && $code ne '-1' && $code ne '' && $errors < 2) {
    # prepare webservice request
    my $json = '{"username":"foo","password":"bar"}';
    my $req = HTTP::Request->new( 'POST', $config->register_uri );
    $req->header( 'Content-Type' => 'application/json' );
    $req->content( $json );
    # call the webservice
    my %options = $config->varlist("^lwp_", 1);
    my $lwp = LWP::UserAgent->new(%options);
    my $t_start = time();
    my $response = $lwp->request( $req );
    my $ttime = time() - $t_start;

    if ($response->is_success) {
      $service->log(1, "%s|REGISTER_PASS|%s", $callid, $response->status_line()." [$ttime]");
      # reset error counter
      $errors = 0;
      # play confirmation
      $code = $agi->get_data(
        $config->register_audio_pass,
        $config->register_timeout,
        $config->register_maxdigits
      );
    }
    else {
      $service->log(1, "%s|REGISTER_FAIL|%s", $callid, $response->status_line()." [$ttime]");
      if (++$errors < 2) {
        # try again
        $code = $agi->get_data(
          $config->register_audio_fail,
          $config->register_timeout,
          $config->register_maxdigits
        );
      }
    }
  } # while
  
  if ($code ne '' && $config->register_audio_helpdesk) {
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
