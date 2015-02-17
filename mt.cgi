#!/usr/bin/env perl

# Movable Type (r) Open Source (C) 2001-2013 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id$

use strict;
use lib 'lib';

require MT::Bootstrap;
my $class = "MT::App::CMS";

$app = $class->new() or die $class->errstr;
local $SIG{__WARN__} = sub { $app->trace( $_[0] ) };
$app->run;
