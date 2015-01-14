#!/usr/bin/perl

use strict;
use lib 'blib/lib';

use Dcrt::AGIService;

Dcrt::AGIService->run( conf_file => 'conf/agid.conf' );

