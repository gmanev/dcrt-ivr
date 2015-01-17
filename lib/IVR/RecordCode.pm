package Dcrt::IVR::RecordCode;

use strict;
use AppConfig qw(:argcount);

sub new {
  my $class = shift;
  my $self = bless ({}, ref($class) || $class);

  my $config = AppConfig->new();
  
  $config->define("record_directory", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => '',
  });

  $config->define("record_format", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => 'wav',
  });

  $config->define("record_digits", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => '#*1234567890ABCD',
  });

  $config->define("record_timeout", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => '15000',
  });

  $config->define("record_beep", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => '1',
  });

  $config->define("record_offset", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => '0',
  });

  $config->define("record_silence", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => '5',
  });

  $config->define("record_audio_start", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => '',
  });

  $config->define("record_audio_success", {
	  ARGCOUNT => ARGCOUNT_ONE,
	  DEFAULT  => '',
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

  my $callerid = $service->input('callerid');

  $agi->answer();

  my $filename = $config->record_directory."/".$callerid."_".time();
  my $code = '-1'; # invalid callerid
  if ($callerid =~ /^\d+$/) {
    $service->log_info('RECORD_ALLOW', $callerid);
    # first attempt
    if (($code = $agi->stream_file( $config->record_audio_start )) eq '0') {
      $code = $agi->record_file(
        $filename,
        $config->record_format,
        $config->record_digits,
        $config->record_timeout,
        $config->record_offset,
        $config->record_beep,
        $config->record_silence
      );
      $service->log_info('RECORD_RESULT', $code);
    }
  }
  else {
    $service->log_info('RECORD_DENY', $callerid);
  }

  while ($code ne '-1') {
    $service->log_info('RECORD_SUCCESS', $filename);
    if (($code = $agi->stream_file( $config->record_audio_success )) eq '0') {
      $filename = $config->record_directory."/".$callerid."_".time();
      $code = $agi->record_file(
        $filename,
        $config->record_format,
        $config->record_digits,
        $config->record_timeout,
        $config->record_offset,
        $config->record_beep,
        $config->record_silence
      );
    }
  } # while

  return 0;
}

1;
