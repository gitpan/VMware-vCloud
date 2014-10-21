package VMware::vCloud;

use LWP;
use strict;

our $VERSION = '1.1';

### External methods

sub new {
  my $class = shift @_;
  my $self  = {};

  $self->{hostname} = shift @_;
  $self->{username} = shift @_;
  $self->{password} = shift @_;
  $self->{orgname}  = shift @_;

  $self->{orgname} = 'System' unless $self->{orgname};

  $self->{debug}        = 0; # Defaults to no debug info
  $self->{die_on_fault} = 1; # Defaults to dieing on an error
  $self->{ssl_timeout}  = 3600; # Defaults to 1h

  bless($self,$class);

  $self->_regenerate();
  
  $self->_debug("Loaded VMware::vCloud v" . our $VERSION . "\n") if $self->{debug};
  return $self;
}

sub config {
  my $self = shift @_;

  my %input = @_;
  my @config_vals = qw/debug die_on_fault hostname orgname password ssl_timeout username/;
  my %config_vals = map { $_,1; } @config_vals;

  for my $key ( keys %input ) {
    if ( $config_vals{$key} ) {
      $self->{$key} = $input{$key};
    } else {
      warn 'Config key "$key" is being ignored. Only the following options may be configured: '
         . join(", ", @config_vals ) . "\n";
    }
  }

  $self->_regenerate();

  my %out;
  map { $out{$_} = $self->{$_} } @config_vals;

  return wantarray ? %out : \%out;
}

### Internal methods

sub _debug {
  my $self = shift @_;
  while ( my $debug = shift @_ ) {
    chomp $debug;
    print STDERR "DEBUG: $debug\n";
  }
}

sub _fault {
  my $self = shift @_;

}

sub _regenerate {
  my $self = shift @_;

  $self->{ua} = LWP::UserAgent->new;
  $self->{ua}->cookie_jar({});

}

### Public methods

sub login {
  my $self = shift @_;
  my $url = URI->new('https://'. $self->{hostname} .'/api/v1.0/login'); # Check API version first!
  my $req = HTTP::Request->new( POST =>  $url ); 

  $req->authorization_basic( $self->{username} .'@'. $self->{orgname}, $self->{password} ); 
  my $response = $self->{ua}->request($req);

print "Authentication status: ".$response->status_line."\n";
print "Response WWW-Authenticate Header: ".$response->header("WWW-Authenticate")."\n";
print $response->content;

  return $response;
}

1;

__END__

=head1 NAME

VMware::vCloud - The VMware vCloud API

=head1 SYNOPSIS

This module has been developed against VMware vCenter director.

  my $vcd = new VMware::vCloud (
    $hostname, $username, $password, $orgname
  );
  
  my $login = $vcd->login;

=head1 DESCRIPTION

This module provides a Perl interface to VMware's vCloud REST interface.

=head1 RETURNED VALUES

Many of the methods return hash references or arrays of hash references that
contain information about a specific "object" or concept on the vCloud Director
server. This is a rough analog to the Managed Object Reference structure of
the VIPERL SDK without the generic interface for retireval.

=head1 EXAMPLE SCRIPTS

Included in the distribution of this module are several example scripts. Hopefully
they provide an illustrative example of the vCloud API. All scripts have
their own POD and accept command line parameters in a similar way to the VIPERL
SDK utilities and vghetto scripts.

    conditions.pl - An example displaying an objects conditions.

=head1 PERL MODULE METHODS

These methods are not direct API calls. They represent the methods that create
or module as a "wrapper" for the Labmanager API.

=head2 new

This method creates the Labmanager object.

U<Arguments>

=over

=item * hostname

=item * username

=item * password

=item * organization

=back

=head2 config

  $vcd->config( debug => 1 );

=over 4

=item debug - 1 to turn on debugging. 0 for none. Defaults to 0.

=item die_on_fault - 1 to cause the program to die verbosely on a soap fault. 0 for the fault object to be returned on the call and for die() to not be called. Defaults to 1. If you choose not to die_on_fault (for example, if you are writing a CGI) you will want to check all return objects to see if they are fault objects or not.

=item ssl_timeout - seconds to wait for timeout. Defaults to 3600. (1hr) This is how long a transaction response will be waited for once submitted. For slow storage systems and full clones, you may want to up this higher. If you find yourself setting this to more than 6 hours, your Lab Manager setup is probably not in the best shape.

=item hostname, orgname, username and password - All of these values can be changed from the original settings on new(). This is handing for performing multiple transactions across organizations.

=back

=head1 BUGS AND LIMITATIONS

=head1 CONFUSING ERROR CODES

=head1 WISH LIST

If someone from VMware is reading this, and has control of the API, I would
dearly love a few changes, that might help things:

 (more soon)

=head1 VERSION

  Version: v1.1 (2011/06/16)

=head1 AUTHOR

  Phillip Pollard, <bennie@cpan.org>

=head1 CONTRIBUTIONS

  stu41j - http://communities.vmware.com/people/stu42j

=head1 DEPENDENCIES

  LWP

=head1 LICENSE AND COPYRIGHT

  Released under Perl Artistic License

=head1 SEE ALSO

 VMware vCloud Director
  http://www.vmware.com/products/vcloud/

 VMware vCloud API Specification v1.0
  http://communities.vmware.com/docs/DOC-12464

 VMware vCloud API Programming Guide v1.0
  http://communities.vmware.com/docs/DOC-12463
  
 vCloud API and Admin API v1.0 schema definition files
  http://communities.vmware.com/docs/DOC-13564
  
 VMware vCloud API Communities
  http://communities.vmware.com/community/vmtn/developer/forums/vcloudapi

=cut