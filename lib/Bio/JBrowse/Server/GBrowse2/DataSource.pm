package Bio::JBrowse::Server::GBrowse2::DataSource;
use Moose;
use namespace::autoclean;
use Path::Class ();

use Text::ParseWords;

use Bio::Graphics::FeatureFile;

has 'name' => ( documentation => <<'',
name of the data source

    is  => 'ro',
    isa => 'Str',
    required => 1,
  );

has 'description' => ( documentation => <<'',
short description of this data source - one line

    is => 'ro',
    isa => 'Str',
    required => 1,
  );

has 'extended_description' => ( documentation => <<'',
fuller description of this data source, 1-2 sentences

    is => 'ro',
    isa => 'Maybe[Str]',
  );

has 'config_manager' => ( documentation => <<'',
ConfigManager-consuming object this data source belongs to

    is => 'ro',
    required => 1,
    weak_ref => 1,
  );

has 'path' => ( documentation => <<'',
absolute path to the data source's config file

    is  => 'ro',
    isa => 'Path::Class::File',
    required => 1,
   );

has 'config' => ( documentation => <<'',
the parsed config of this data source, a Bio::Graphics::FeatureFile

    is  => 'ro',
    isa => 'Bio::Graphics::FeatureFile',
    lazy_build => 1,
   ); sub _build_config {
       Bio::Graphics::FeatureFile->new(
           -file => shift->path->stringify,
           -safe => 1,
          );
   }

has '_databases' => (
    is => 'ro',
    isa => 'HashRef',
    traits => ['Hash'],
    lazy_build => 1,
    handles => {
        databases => 'values',
        database  => 'get',
    },
   );
sub _build__databases {
    my $self = shift;
    local $_; #< Bio::Graphics::* sloppily clobbers $_
    my $conf = $self->config;
    my @dbs =  grep /:database$/i, $self->config->configured_types;
    return {
        map {
            my $dbname = $_;
            my $adaptor = $conf->setting( $dbname => 'db_adaptor' )
                or confess "no db adaptor for [$_] in ".$self->path->basename;
            my @args = shellwords( $conf->setting( $dbname => 'db_args' ));
            Class::MOP::load_class( $adaptor );
            my $conn = eval {
                local $SIG{__WARN__} = sub { warn @_ if $self->debug };
                $adaptor->new( @args );
            };
            if( $@ ) {
                warn $self->path->basename." [$dbname] not available\n";
                warn $@ if $self->debug;
                ()
            } else {
                $dbname =~ s/:database$//;
                $dbname => $conn
            }
        } @dbs
       };
}


has 'debug' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
   );

__PACKAGE__->meta->make_immutable;
1;
