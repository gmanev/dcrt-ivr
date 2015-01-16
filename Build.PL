use Module::Build;
use strict;

my $class = Module::Build->subclass (
	class	=> 'My::Builder',
	code	=> q{
    sub ACTION_install {
		  my $self = shift;
		  my $destdir = $self->destdir || '';
      $self->do_system("mkdir", ("-p", $destdir."/usr/sbin"));
      $self->do_system("mkdir", ("-p", $destdir."/etc/rc.d/init.d"));
      $self->do_system("mkdir", ("-p", $destdir."/etc/sysconfig"));

      $self->do_system("install", ("etc/rc.redhat.agid", $destdir."/etc/rc.d/init.d/agid"));
      $self->do_system("install", ("bin/agid", $destdir."/usr/sbin"));

      $self->do_system("cp", ("etc/agid.conf", $destdir."/etc"));
      $self->do_system("cp", ("etc/sysconfig", $destdir."/etc/sysconfig/agid"));

     	$self->SUPER::ACTION_install;
    }
	}
);

my $m = $class->new (
  dist_name	=> 'dcrt-ivr',
  dist_version	=> '0.0.1',
  dist_author => 'Georgi Manev <gmanev@newtech-bt.bg>',
  dist_abstract => 'Dcrt IVR',
  module_name => 'Dcrt::AGIService',
  license		=> 'gpl',
  requires => {
	    'Asterisk::FastAGI' => 0.02
  },
  pm_files =>
	{
	    'lib/AGIService.pm'            	=> 'lib/Dcrt/AGIService.pm',
	    'lib/IVR/RegisterCode.pm'      	=> 'lib/Dcrt/IVR/RegisterCode.pm',
	    'lib/IVR/RecordCode.pm'       	=> 'lib/Dcrt/IVR/RecordCode.pm'
	},
	script_files => [qw(
    bin/agid
	)],
);

$m->create_build_script;
