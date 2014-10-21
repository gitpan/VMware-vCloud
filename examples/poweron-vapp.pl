#!/usr/bin/perl -I../lib
=head1 poweron-vapp.pl

This example script uses the API to list available vApps and then the power-on
the vApp selected by the user.

=head2 Usage

  ./poweron-vapp.pl --username USER --password PASS --orgname ORG --hostname HOST
  
Orgname is optional. It will default to "System" if not given. 

=cut

use Data::Dumper;
use Getopt::Long;
use VMware::vCloud;
use strict;

my $version = ( split ' ', '$Revision: 1.3 $' )[1];

my ( $username, $password, $hostname, $orgname );

my $ret = GetOptions ( 'username=s' => \$username, 'password=s' => \$password,
                       'orgname=s' => \$orgname, 'hostname=s' => \$hostname );

die "Check the POD. This script needs command line parameters." unless
 $username and $password and $hostname;

my $vcd = new VMware::vCloud ( $hostname, $username, $password, $orgname, { debug => 1 } );

# Grab a list of vapps and let the user pick one to power on

my %vapps = $vcd->list_vapps();
my @vapps = sort { lc($vapps{$a}) cmp lc($vapps{$b}) } keys %vapps; # Put the names in alpha order

my $line = '='x80;
my $i = 1;

print "$line\n\nSelect a VM to power on:\n";

for my $vapp (@vapps) {
  print "   $i. \"$vapps{$vapp}\"\n";
  $i++;
}

print "\n$line\n";

my $id = <STDIN>;
chomp $id;
$id -= 1;

my $vappid = $vapps[$id];
print "\nGoing to try powering $vapps{$vappid} ON.\n";
print "\n$line\n";

# get the selected vApp and power it on.

my $vapp = $vcd->get_vapp($vappid);
my $ret = $vapp->power_on();

# look at the return code from the power-on

print "\n";
if ( ref $ret eq 'ARRAY' ) {
  print $ret->[0] .': '. $ret->[1];
} else {
  print Dumper($ret);
}
print "\n\n";