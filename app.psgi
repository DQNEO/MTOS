#!/usr/bin/env perl

package main;
use strict;
use warnings;
use lib 'lib';
use lib 'extlib';
require 'lib/MT/PSGI.pm';
my $app = MT::PSGI->new()->to_app();
