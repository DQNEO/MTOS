use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use MT::PSGI;

MT::PSGI->new->to_app;
