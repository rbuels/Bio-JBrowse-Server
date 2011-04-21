package Bio::JBrowse::Server::Role::GBrowse2::ConfigManager;
use Moose::Role;
use namespace::autoclean;

use MooseX::Types::Path::Class qw( Dir );

use Bio::JBrowse::Server::GBrowse2::DataSource;

has 'conf_dir' => (
    is         => 'ro',
    isa        => Dir,
    coerce     => 1,
    required   => 1,
  );

### our configuration objects
has 'config_master' => (
    is => 'ro',
    lazy_build => 1,
   ); sub _build_config_master {

       my $master_file = shift->conf_dir->file('GBrowse.conf');
       unless( -f $master_file ) {
           warn __PACKAGE__.": master conf file $master_file not found";
           return;
       }

       my $ff = Bio::Graphics::FeatureFile->new( -file => "$master_file" );
       $ff->safe( 1 ); #< mark the file as safe, so we can use code refs
       return $ff;
   }

# provides data_sources(), list of data source names, and
# data_source($name) accessor, to get a certain data source by name
has '_data_sources' => (
    is         => 'ro',
    isa        => 'HashRef',
    traits     => ['Hash'],
    lazy_build => 1,
    handles => {
        data_sources => 'values',
        data_source  => 'get',
    },
   ); sub _build__data_sources {
       my $self = shift;

       unless( $self->config_master ) {
           warn __PACKAGE__.': no master config found, skipping data sources configuration';
           return {};
       }


       my %sources;
       foreach my $type ( $self->config_master->configured_types ) {

           # absolutify the path from the config file
           my $path = $self->config_master->setting( $type => 'path' )
               or die "no path configured for [$type] in ".$self->config_master."\n";
           $path = Path::Class::File->new( $path );
           unless( $path->is_absolute ) {
               $path = $self->conf_dir->file( $path );
           }

           $sources{$type} = Bio::JBrowse::Server::GBrowse2::DataSource->new(
               name           => $type,
               path           => $path,
               config_manager => $self,
               description    => $self->config_master->setting( $type => 'description' ),
               extended_description => $self->config_master->setting( $type => 'extended_description' ),
              );
       }

       return \%sources;
   }


1;
