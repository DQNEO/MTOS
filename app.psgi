#!/usr/bin/env perl

package main;
use strict;
use warnings;
use lib 'lib';
use lib 'extlib';
use MT::PSGI;
my $app = MT::PSGI->new()->to_app();
