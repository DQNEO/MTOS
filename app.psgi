#!/usr/bin/env perl

# Movable Type (r) Open Source (C) 2001-2013 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id$

use strict;
use warnings;
use lib 'lib';
use lib 'extlib';
use MT::PSGI;
my $app = MT::PSGI->new()->to_app();
