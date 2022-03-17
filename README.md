# VMware-AutoRecover
This script will power on VMs in a cluster (HA and DRS compatible) after a graceful shutdown event. It is frequent enough in small office or branch locations that when the hosts lose power and a battery backup or power control system issues shutdown commands, there is not a graceful way to bring systems back up. 

*This script uses PowerCLI*

## Notes About Script ##

1. First run should be interactive as system will prompt for credentials. 
2. Password is sent in clear text first time and stored in PowerCLI credential store afterwards.
3. Change the VCSURL variable to match your vCenter FQDN or IP accordingly.
4. This process does require adding a prefix to the VM names. Prefixes are as follows:

> **Retired = Do Not Restore Power and Ignore** <br>
> **Priority = Start these VMs first. They are sorted into variable by name so Priority1 will start before Priority2** <br>
> **Every Other VM Without Custom Names = Start after the Priority VM List** <br>

## Usage ##

This script can be run manually after an outage or attached to any number of automation tasks/events. I have also tested using this script on a physical Windows box and linking it to a scheduled task that kicks off when a particular event ID (unexpected power loss) is shown for that physical machine. 

This script can also be run against an environment with VMs already powered on without any damage. This means you can create test VMs with priority numbers/etc. and test the startup sequence and trigger without needing an outage each time. 
