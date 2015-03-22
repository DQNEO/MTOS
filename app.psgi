use strict;
use warnings;
use lib './lib';
use MT::PSGI;

MT::PSGI->new->to_app;
