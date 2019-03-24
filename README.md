
## Check HP Supply

This check plugin has been written by Martin Müller and can be found at 
https://www.thesysadmin.net/projects/plugin-check_hp_supply/


```bash
check_hp_supply.pl Version: 1.2.1
Plugin for Nagios and Icinga 
checks the given Supply on a HP-Printer via SNMP.
To use this Plugin your HP-Printers must have SNMP enabled.

Usage:
   -H (--hostname)   Hostname to query - (required)
   -C (--community)  SNMP read community (default=public)
   -v (--snmp_version)  1 for SNMP v1 (default)
                        2 for SNMP v2c
   -p (--snmp_port)  SNMP Port (default=161)
   -a (--action)     Specify one component of your HP-Printer you want to check (required)
                        supply_black - Checks remaining Toner in Percent of the Black-Cartridge
                        supply_cyan - Checks remaining Toner in percent of the Cyan-Cartridge (use only for Color-Printers!)
                        supply_magenta - Checks remaining Toner in percent of the Magenta-Cartridge (use only for Color-Printers!)
                        supply_yellow - Checks remaining Toner in percent of the Yellow-Cartridge (use only for Color-Printers!)
                        transfer_kit - Checks Status in percent of the Transfer-Kit / Imaging Drum (only available/tested on HP Color LaserJet 2550 and 4650)
                        fuser_kit - Checks Status in percent of the Fuser-Kit (only available/tested on HP Color LaserJet 4650)
                        maintenance_kit - Checks Status in percent of the Maintenance-Kit (only available/tested on HP LaserJet 4200/4250/4300)
                        drum_kit - Checks Status in percent of the Drum-Kit (only available/tested on Hp Color LaserJet 4550)
   -w (--warning)    Warning threshold
                        Default is 30 percent
   -c (--critical)   Critical threshold
                        Default is 15 percent
   -t (--timeout)    Seconds before the plugin times out (default=15)
   -V (--version)    Plugin version
   -h (--help)       Usage help 

See http://nagiosplug.sourceforge.net/developer-guidelines.html#THRESHOLDFORMAT
for details and examples of the threshold form
```

### What is this fork ? 

This fork of the plug-in replaces `Nagios::Plugin` with the more generic `Monitoring::Plugin` CPAN module.
Nothing else has changed
