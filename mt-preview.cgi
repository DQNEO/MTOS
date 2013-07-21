#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);

#======= settings ==============
my $tpl = 'entry.tpl';
my $config_file = 'mt-config.cgi';

#===============================
my $q = CGI->new;
my $mt = MTFastPreview->new;
my $entry_id = $q->param('id') ? $q->param('id') : 0;
$mt->preview($tpl, $config_file, $entry_id);

package MTFastPreview;
use strict;
use warnings;
use Encode;
use FindBin;
use DBI;
use Data::Dumper;

sub _thaw_mt_4 {            # JSON
    my ($frozen) = @_;
    return unless substr( $frozen, 0, 4 ) eq 'SERG';

    my $thawed;
    my $pos = 12;           # skips past signature and version block

    require JSON;
    $thawed = JSON::decode_json( substr( $frozen, $pos ) );
    $thawed = {} unless defined $thawed;
    \$thawed;
}

sub new {
    my $class = shift;
    bless {}, $class;
}

sub _parse_config {
    my $self = shift;
    my $config_file = shift;
    my $config_path = $FindBin::Bin . '/' . $config_file;
    my $text = $self->read_file($config_path);
    my %config = $text =~ /^(\w+) +(.+)$/mg;

    return \%config;
}

sub preview {
    my $self = shift;
    my $tpl = shift;
    my $config_file = shift;
    my $entry_id = shift;

    my $config2 = $self->_parse_config($config_file);


#     print Dumper $config, $config2;
#     exit;

    my $params = $self->_get_entry($config2, $entry_id);
    $self->_render($tpl, $params);

}

sub _get_entry {
    my $self = shift;
    my $config = shift;
    my $entry_id = shift;

    my $dbh = DBI->connect("DBI:mysql:$config->{Database}:$config->{DBHost}", $config->{DBUser}, $config->{DBPassword}) or die "cannot connect db $@";    
    my $sql = " select session_data from mt_session where session_kind = 'AS' AND session_id like 'autosave:%type=entry:id=$entry_id:blog_id=5\%' order by session_start desc; ";

    my $sth =  $dbh->prepare($sql);
    $sth->execute;
    
    my ($entry) = ($sth->fetchrow_array);
    return unless $entry;

    my $sess =  _thaw_mt_4($entry);

    # print "Content-type:text/html\n\n";
    # use Data::Dumper;
    # print Dumper $sess;
    # die;

    my $params = {
	title => $$sess->{title},
	body  => $$sess->{text} . $$sess->{text_more},
    };
    
}


sub _render {
    my $self = shift;
    my $tplname = shift;
    my $params = shift;

    if (!$params) {
	$params = {title => '', body => '',};
    }


    my $filename  = $FindBin::Bin . '/' . $tplname;
    my $text = $self->read_file($filename);

    my $tpl = decode('utf8', $text);
    
    $tpl =~ s/{{\$title}}/$params->{title}/g;
    $tpl =~ s/{{\$body}}/$params->{body}/g;
    
    print "Content-type: text/html; charset=utf8\n\n";
    print encode('utf8', $tpl);
}

sub read_file {
    my $self = shift;
    my $filename = shift;
    open  my $fh, $filename  or die "cannot open file $filename\n";
    my $text = do { local( $/ ) ; <$fh> };
}
