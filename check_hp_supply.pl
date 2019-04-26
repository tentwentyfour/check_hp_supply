#!/usr/bin/perl -w

#
# Copyright (C) 2012 Martin Mueller,
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
# Report bugs to:  hello@tentwentyfour.lu

$ENV{'PATH'}='';
$ENV{'BASH_ENV'}='';
$ENV{'ENV'}='';

use POSIX;
use warnings;
use strict;

# Find the Nagios::Plugin lib. Change this path if necessary
use FindBin;
use lib "$FindBin::Bin/../perl/lib";
use Monitoring::Plugin qw(%ERRORS);

use Net::SNMP;
use Getopt::Long qw(:config no_ignore_case bundling);

# define Constants

use vars qw($PROGRAMNAME $SHORTNAME $AUTHOR $COPYR $VERSION);
$PROGRAMNAME = "$FindBin::Script";
$SHORTNAME = "Check HP Supply-Status";
$AUTHOR = "Martin Mueller";
$COPYR = "Copyright (C) 2012";
$VERSION = "Version: 1.2.1";

sub usage();
sub help();

# define Commandline-Options

my $host = undef;
my $community = "public";
my $snmp_version = 1;
my $snmp_port = 161;
my $action = undef;
my $warning = 30;
my $critical = 15;
my $timeout = 15;
my $help = undef;
my $printversion = undef;


my $np = Monitoring::Plugin->new(
                shortname => "$SHORTNAME",
);

# get Options

GetOptions(
   "H|host=s"           => \$host,
   "C|community=s"      => \$community,
   "p|snmp_port=i"      => \$snmp_port,
   "v|snmp_version=i"   => \$snmp_version,
   "a|action=s"         => \$action,
   "w|warning=i"        => \$warning,
   "c|critical=i"       => \$critical,
   "t|timeout=i"        => \$timeout,
   "h|help"             => \$help,
   "V|version"          => \$printversion,
   );

if ($help) {
	help();
	}

if ($printversion) {
	printf "\n";
	printf "$PROGRAMNAME - $VERSION\n\n";
	printf "$COPYR $AUTHOR\n";
	printf "This programm comes with ABSOLUTELY NO WARRANTY\n";
	printf "This programm is licensed under the terms of the GNU General Public License";
	printf "\n\n";
	exit($ERRORS{'UNKNOWN'});
	}

if (!defined $host) {
	printf "\nMissing argument [host]. Please specify a hostname or ip address\n";
	usage();
	}
	
if ($snmp_version =~ /[^12]/) {
	printf "\nSNMP version: $snmp_version is not supported. Please use SNMP version 1 or 2\n";
	usage();
	}

if (!defined $action) {
	printf "\nMissing argument [action]. Please specify what you want supply you want to check on your HP-Printer\n";
	usage();
	}

$SIG{'ALRM'} = sub {
	$np->nagios_die("No snmp response from $host (alarm)");
	};

alarm($timeout);

# ------------------------------------------------------
# Start here with Main Program
# ------------------------------------------------------

my $session;
my $error;

my $base_oid = ".1.3.6.1.2.1.43.11.1.1";
my $supply_type_oid = ".6.1";
my $supply_capacity_oid = ".8.1";
my $supply_used_oid = ".9.1";

my $supply_black_oid = ".1";
my $supply_cyan_oid = ".2";
my $supply_magenta_oid = ".3";
my $supply_yellow_oid = ".4";
my $supply_transfer_oid = ".5";
my $supply_fuser_oid = ".6";
my $supply_drum_oid = ".7";
my $supply_maintenance_oid = ".2";

my $supply_oid = undef;

if (lc($action) eq "supply_black")			{ $supply_oid = $supply_black_oid }
elsif (lc($action) eq "supply_cyan")		{ $supply_oid = $supply_cyan_oid }
elsif (lc($action) eq "supply_magenta")		{ $supply_oid = $supply_magenta_oid }
elsif (lc($action) eq "supply_yellow")		{ $supply_oid = $supply_yellow_oid }
elsif (lc($action) eq "transfer_kit")		{ $supply_oid = $supply_transfer_oid }
elsif (lc($action) eq "fuser_kit")			{ $supply_oid = $supply_fuser_oid }
elsif (lc($action) eq "maintenance_kit")	{ $supply_oid = $supply_maintenance_oid }
elsif (lc($action) eq "drum_kit")			{ $supply_oid = $supply_drum_oid }
else {
	printf "\nAction $action not supported. \n";
	printf "Please use one of |supply_black|supply_cyan|supply_magenta|supply_yellow|transfer_kit|fuser_kit|maintenance_kit|drum_kit|\n";
	usage();
	}

&create_snmpsession();

my $printer_type_oid = ".1.3.6.1.2.1.25.3.2.1.3.1";
my $printer_type = undef;

$printer_type = &get_snmpdata($printer_type_oid);

# If given SNMP-Community does not deliver any value, it will try with public-access (useful on HP LJ-2600)
if (!defined $printer_type) {
  $community = "public";
  $printer_type = &get_snmpdata($printer_type_oid);
  }

my $supply_capacity = &get_snmpdata($base_oid,$supply_capacity_oid,$supply_oid);
my $supply_used = &get_snmpdata($base_oid,$supply_used_oid,$supply_oid);
my $supply_type = &get_snmpdata($base_oid,$supply_type_oid,$supply_oid);

my $supply_status = (100*$supply_used/$supply_capacity);

if ($supply_status == "-2") {
        $np->add_message('CRITICAL',$supply_type." - Level too low to get a reading");
        }
elsif ($supply_status <= $critical) {
	$np->add_message('CRITICAL',$supply_type." = ".$supply_status." %");
	}
elsif ($supply_status <= $warning) {
	$np->add_message('WARNING',$supply_type." = ".$supply_status." %");
	}
elsif ($supply_status >= $warning) {
	$np->add_message('OK',$supply_type." = ".$supply_status." %");
	}
else {
	$np->add_message('UNKNOWN',"Something went wrong ".$supply_type." is ".$supply_status." %");
	}

# Writing Performance-Data
$np->add_perfdata(
	label => $supply_type,
	value => $supply_status,
	uom => "Percent",
	min => 0,
	max => 100,
	);

&end_snmpsession();

# Create Nagios-Output and End the Plugin

my ($code, $message) = $np->check_messages(join => "<BR>",join_all => "<BR>");
$np->nagios_exit($code,$message);

# ------------------------------------------------------
# End Main Program
# ------------------------------------------------------

sub create_snmpsession() {
	($session,$error) = Net::SNMP->session(Hostname => $host, Community => $community, Port => $snmp_port, Version => $snmp_version);
	$np->nagios_die("Unable to open SNMP connection. ERROR: $error") if (!defined($session));
	}

sub end_snmpsession() {
	$session->close;
	alarm(0);
	}

sub get_snmpdata() {
	my $oid_requested = $_[0];
	my $oid_option1 = $_[1];
	my $oid_option2 = $_[2];
	my $oid_value_hash;
	my $oid_value;
	my $session;
	my $error;

        ($session,$error) = Net::SNMP->session(Hostname => $host, Community => $community, Port => $snmp_port, Version => $snmp_version);
	$np->nagios_die("Unable to open SNMP connection. ERROR: $error") if (!defined($session));	

# if OID-Option is given ask them, otherwise do oid only

	if (defined $oid_option1 && $oid_option2) {
		$oid_value_hash = $session->get_request($oid_requested.$oid_option1.$oid_option2);
		$np->nagios_die("Unable to read SNMP-OID. ERROR: ".$session->error()) if (!defined($oid_value_hash));
        	$oid_value = $oid_value_hash->{$oid_requested.$oid_option1.$oid_option2};
		}
	elsif (defined $oid_option1) {
		$oid_value_hash = $session->get_request($oid_requested.$oid_option1);
		$np->nagios_die("Unable to read SNMP-OID. ERROR: ".$session->error()) if (!defined($oid_value_hash));
		$oid_value = $oid_value_hash->{$oid_requested.$oid_option1};
		}
	else {
	    $oid_value_hash = $session->get_request($oid_requested);
		$np->nagios_die("Unable to read SNMP-OID. ERROR: ".$session->error()) if (!defined($oid_value_hash));
        $oid_value = $oid_value_hash->{$oid_requested};
		}

        $session->close;
		alarm(0);

        return $oid_value;
        }

sub usage () {
	printf "\n";
	printf "USAGE: $PROGRAMNAME -H <hostname> [-C <community>] -a <action>\n\n";
	printf "$PROGRAMNAME $VERSION\n";
	printf "$COPYR $AUTHOR\n";
	printf "This programm comes with ABSOLUTELY NO WARRANTY\n";
	printf "This programm is licensed under the terms of the GNU General Public License";
	printf "\n\n";
	exit($ERRORS{'UNKNOWN'});
	}

sub help () {
	printf "\n\n$PROGRAMNAME $VERSION\n";
	printf "Plugin for Nagios and Icinga \n";
	printf "checks the given Supply on a HP-Printer via SNMP.\n";
	printf "To use this Plugin your HP-Printers must have SNMP enabled.\n";
	printf "\nUsage:\n";
	printf "   -H (--hostname)   Hostname to query - (required)\n";
	printf "   -C (--community)  SNMP read community (default=public)\n";
	printf "   -v (--snmp_version)  1 for SNMP v1 (default)\n";
	printf "                        2 for SNMP v2c\n";
	printf "   -p (--snmp_port)  SNMP Port (default=161)\n";
	printf "   -a (--action)     Specify one component of your HP-Printer you want to check (required)\n";
	printf "                        supply_black - Checks remaining Toner in Percent of the Black-Cartridge\n";
	printf "                        supply_cyan - Checks remaining Toner in percent of the Cyan-Cartridge (use only for Color-Printers!)\n";
	printf "                        supply_magenta - Checks remaining Toner in percent of the Magenta-Cartridge (use only for Color-Printers!)\n";
	printf "                        supply_yellow - Checks remaining Toner in percent of the Yellow-Cartridge (use only for Color-Printers!)\n";
	printf "                        transfer_kit - Checks Status in percent of the Transfer-Kit / Imaging Drum (only available/tested on HP Color LaserJet 2550 and 4650)\n";
	printf "                        fuser_kit - Checks Status in percent of the Fuser-Kit (only available/tested on HP Color LaserJet 4650)\n";
	printf "                        maintenance_kit - Checks Status in percent of the Maintenance-Kit (only available/tested on HP LaserJet 4200/4250/4300)\n";
	printf "                        drum_kit - Checks Status in percent of the Drum-Kit (only available/tested on Hp Color LaserJet 4550)\n";
	printf "   -w (--warning)    Warning threshold\n";
	printf "                        Default is 30 percent\n";
	printf "   -c (--critical)   Critical threshold\n";
	printf "                        Default is 15 percent\n";
	printf "   -t (--timeout)    Seconds before the plugin times out (default=15)\n";
	printf "   -V (--version)    Plugin version\n";
	printf "   -h (--help)       Usage help \n\n";
	printf "See http://nagiosplug.sourceforge.net/developer-guidelines.html#THRESHOLDFORMAT\n";
	printf "for details and examples of the threshold form\n\n";
	exit($ERRORS{'OK'});
}

