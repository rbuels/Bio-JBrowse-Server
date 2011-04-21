use strict;
use warnings;

use Test::More;
use Test::Warn;

my $m = MyMgr->new( conf_dir => 't/data/gbconf/1' );

can_ok $m, qw( data_sources config_master );

can_ok $m->config_master, qw( configured_types );

is scalar( $m->data_sources ),   11,
   'got right number of data sources';

can_ok $m->data_source('ITAG1_genomic'),
       qw( databases  config  name description );

warning_like {
    is scalar( $m->data_source('ITAG1_genomic')->databases ), 0,
       "can't connect to the faked-out database, but doesn't die either";
} qr/not available/;

done_testing;

BEGIN {
    package MyMgr;
    use Moose;
    with 'Bio::JBrowse::Server::Role::GBrowse2::ConfigManager';
}
