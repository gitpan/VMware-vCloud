package VMware::vCloud;

use Cache::Bounded;
use VMware::API::vCloud;
use strict;

our $VERSION = 'v2.04';

### External methods

sub new {
  my $class = shift @_;
  our $host = shift @_;
  our $user = shift @_;
  our $pass = shift @_;
  our $org  = shift @_;
  our $conf = shift @_;

  $org = 'System' unless $org; # Default to "System" org

  my $self  = {};
  bless($self);

  our $cache = new Cache::Bounded;

  $self->{api} = new VMware::API::vCloud (our $host, our $user, our $pass, our $org, our $conf);
  $self->{raw_login_data} = $self->{api}->login();

  return $self;
}

sub login {
  my $self = shift @_;
  return $self->list_orgs(@_);
}

# Returns a hasref of the org

sub get_org {
  my $self = shift @_;
  my $id   = shift @_;

  my $org = our $cache->get('get_org:'.$id);
  return %$org if defined $org;
  
  my $raw_org_data = $self->{api}->org_get($id);

  my %org;
  $org{description} = $raw_org_data->{Description}->[0];
  $org{name}        = $raw_org_data->{name};

  $raw_org_data->{href} =~ /([^\/]+)$/;
  $org{id} = $1;

  $org{contains} = {};
  
  for my $link ( @{$raw_org_data->{Link}} ) {
    $link->{type} =~ /^application\/vnd.vmware.vcloud.(\w+)\+xml$/;
    my $type = $1;
    $link->{href} =~ /([^\/]+)$/;
    my $id = $1;
    
    next if $type eq 'controlAccess';
    
    $org{contains}{$type}{$id} = $link->{name};
  }

  $cache->set('get_org:'.$id,\%org);
  return %org;
}

# Returns a hasref of the vdc

sub get_vdc {
  my $self = shift @_;
  my $id = shift @_;

  my $vdc = our $cache->get('get_vdc:'.$id);
  return %$vdc if defined $vdc;

  my $raw_vdc_data = $self->{api}->vdc_get($id);

  my %vdc;
  $vdc{description} = $raw_vdc_data->{Description}->[0];
  $vdc{name}        = $raw_vdc_data->{name};

  $raw_vdc_data->{href} =~ /([^\/]+)$/;
  $vdc{id} = $1;

  $vdc{contains} = {};
  
  for my $link ( @{$raw_vdc_data->{Link}} ) {
    $link->{type} =~ /^application\/vnd.vmware.vcloud.(\w+)\+xml$/;
    my $type = $1;
    $link->{href} =~ /([^\/]+)$/;
    my $id = $1;
    
    next if $type eq 'controlAccess';
    
    $vdc{contains}{$type}{$id} = $link->{name};
  }
  
  $cache->set('get_vdc:'.$id,$raw_vdc_data);
  return %$raw_vdc_data;
}

# Returns a hash of orgs the user can access

sub list_orgs {
  my $self = shift @_;

  my %orgs;
  for my $orgname ( keys %{$self->{raw_login_data}->{Org}} ) {
    my $href = $self->{raw_login_data}->{Org}->{$orgname}->{href};
    $href =~ /([^\/]+)$/;
    my $orgid = $1;
    $orgs{$orgid} = $orgname;
  }

  return wantarray ? %orgs : \%orgs;  
}

sub list_templates {
  my $self  = shift @_;
  my $orgid = shift @_;

  my $templates = our $cache->get('list_templates:'.$orgid);
  return %$templates if defined $templates;

  my %orgs = $self->list_orgs();

  my %vdcs;
  
  for my $orgid ( keys %orgs ) {
    my %org = $self->get_org($orgid);
    for my $vdcid ( keys %{$org{contains}{vdc}} ) {
      $vdcs{$vdcid}++;
    }
  }

  my %templates;
  
  for my $vdcid ( keys %vdcs ) {
    my %vdc = $self->get_vdc($vdcid);
    for my $entity ( @{$vdc{ResourceEntities}} ) {
      for my $name ( keys %{$entity->{ResourceEntity}} ) {
        next unless $entity->{ResourceEntity}->{$name}->{type} eq 'application/vnd.vmware.vcloud.vAppTemplate+xml';
        my $href = $entity->{ResourceEntity}->{$name}->{href};
        $href =~ /([^\/]+)$/;
        my $id = $1;
        $templates{$id} = $name;
      }
    }
  }

  $cache->set('list_templates:'.$orgid,\%templates);
  return %templates;
}

sub list_vapps {
  my $self  = shift @_;
  my $orgid = shift @_;

  my $vapps = our $cache->get('list_vapps:'.$orgid);
  return %$vapps if defined $vapps;

  my %orgs = $self->list_orgs();

  my %vdcs;
  
  for my $orgid ( keys %orgs ) {
    my %org = $self->get_org($orgid);
    for my $vdcid ( keys %{$org{contains}{vdc}} ) {
      $vdcs{$vdcid}++;
    }
  }

  my %vapps;
  
  for my $vdcid ( keys %vdcs ) {
    my %vdc = $self->get_vdc($vdcid);
    for my $entity ( @{$vdc{ResourceEntities}} ) {
      for my $name ( keys %{$entity->{ResourceEntity}} ) {
        next unless $entity->{ResourceEntity}->{$name}->{type} eq 'application/vnd.vmware.vcloud.vApp+xml';
        my $href = $entity->{ResourceEntity}->{$name}->{href};
        $href =~ /([^\/]+)$/;
        my $id = $1;
        $vapps{$id} = $name;
      }
    }
  }

  $cache->set('list_vapps:'.$orgid,\%vapps);
  return %vapps;
}

1;

__END__

=head1 NAME

VMware::vCloud - VMware vCloud Director

=head1 SYNOPSIS

  my $vcd = new VMware::vCloud ( $hostname, $username, $password, $orgname, { debug => 1 } );
  
  my %vapps = $vcd->list_vapps();

=head1 DESCRIPTION

This module provides a Perl interface to VMware's vCloud Director.

=head1 EXAMPLE SCRIPTS

Included in the distribution of this module are several example scripts. 
Hopefully they provide an illustrative example of the use of vCloud Director. 
All scripts have their own POD and accept command line parameters in a similar 
way to the VIPERL SDK utilities and vghetto scripts.

	login.pl - An example script that demonstrates logging in to the server.
	org_get.pl - Selects a random organization and prints a Data::Dumper dump of it's information.
	list-vapps.pl - Prints a list of all VMs the user has access to.

=head1 VERSION

  Version: v2.04 (2011/10/03)

=head1 AUTHOR

  Phillip Pollard, <bennie@cpan.org>

=head1 CONTRIBUTIONS

  stu41j - http://communities.vmware.com/people/stu42j

=head1 DEPENDENCIES

  Cache::Bounded
  VMware::API::vCloud

=head1 LICENSE AND COPYRIGHT

  Released under Perl Artistic License

=cut
